import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// NOTE: requires the `record` package - add `record: ^5.1.2` (or latest) to
// pubspec.yaml. Not previously a dependency; speech_to_text never exposes
// raw audio bytes, only recognized text, so it can't feed Sahara's STT.

class VoiceService {
  VoiceService({
    AudioPlayer? audioPlayer,
    FlutterTts? fallbackTts,
    AudioRecorder? recorder,
  })  : _audioPlayer = audioPlayer,
        _fallbackTts = fallbackTts,
        _recorder = recorder ?? AudioRecorder();

  static const String ttsProvider = String.fromEnvironment('TTS_PROVIDER');
  static const String saharaTtsEdgeFunction = String.fromEnvironment(
    'SAHARA_TTS_EDGE_FUNCTION',
    defaultValue: 'sahara-tts',
  );

  static const String omnivoiceApiUrl =
      String.fromEnvironment('OMNIVOICE_API_URL');
  static const String omnivoiceApiKey =
      String.fromEnvironment('OMNIVOICE_API_KEY');

  final SpeechToText _speech = SpeechToText();
  final AudioRecorder _recorder;
  AudioPlayer? _audioPlayer;
  FlutterTts? _fallbackTts;
  String _lastWords = '';
  bool _speechReady = false;
  bool _finalResultDelivered = false;
  ValueChanged<String>? _onFinalResult;
  ValueChanged<String>? _onPartialResult;
  String? _recordingPath;

  // ── Sahara-backed recording flow ──────────────────────────────────
  // Records a real audio clip to disk (unlike speech_to_text, which never
  // exposes raw bytes - only recognized text via the OS recognizer). The
  // caller uploads the returned bytes to the rudo-chat edge function's
  // audio_base64 path, which forwards to Sahara STT server-side.

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission was not granted.');
    }
    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/rudo_voice_note_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
  }

  /// Stops the active recording and returns the captured audio bytes.
  /// Returns null if nothing was captured (e.g. stop called too soon,
  /// or start() was never called / already stopped).
  Future<Uint8List?> stopRecording() async {
    final path = await _recorder.stop();
    final resolvedPath = path ?? _recordingPath;
    _recordingPath = null;
    if (resolvedPath == null) {
      return null;
    }
    final file = File(resolvedPath);
    if (!await file.exists()) {
      return null;
    }
    final bytes = await file.readAsBytes();
    unawaited(file.delete().catchError((_) => file));
    return bytes.isEmpty ? null : bytes;
  }

  /// Discards the active recording without returning bytes - used when
  /// exiting voice mode mid-recording.
  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
    _recordingPath = null;
  }

  Future<void> startListening({
    String? language,
    ValueChanged<String>? onFinalResult,
    ValueChanged<String>? onPartialResult,
  }) async {
    _lastWords = '';
    _finalResultDelivered = false;
    _onFinalResult = onFinalResult;
    _onPartialResult = onPartialResult;
    _speechReady = _speechReady ||
        await _speech.initialize(
          onError: (error) {
            debugPrint('Speech recognition error: $error');
            _emitFinalResultIfNeeded();
          },
          onStatus: (status) {
            debugPrint('Speech recognition status: $status');
            if (status == 'done' || status == 'notListening') {
              _emitFinalResultIfNeeded();
            }
          },
        );

    if (!_speechReady) {
      throw StateError('Speech recognition is not available on this device.');
    }

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _localeForLanguage(language),
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords.trim();
        if (result.finalResult) {
          _emitFinalResultIfNeeded();
        } else {
          _onPartialResult?.call(_lastWords);
        }
      },
    );
  }

  Future<String> stopAndTranscribe() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _lastWords.trim();
  }

  Future<Uint8List> synthesizeSpeech(String text, String language) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return Uint8List(0);
    }

    if (_shouldUseSahara) {
      return _synthesizeSahara(trimmedText, language);
    }

    return _synthesizeOmniVoice(trimmedText, language);
  }

  Future<void> speakText(String text, String language) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    try {
      final audioBytes = await synthesizeSpeech(trimmedText, language);
      await playAudio(audioBytes);
    } catch (error) {
      debugPrint('Cloud voice synthesis failed, using device TTS: $error');
      await speakWithDeviceVoice(trimmedText, language);
    }
  }

  Future<void> playAudio(Uint8List audioBytes) async {
    if (audioBytes.isEmpty) {
      return;
    }
    final audioPlayer = _audioPlayer ??= AudioPlayer();
    await audioPlayer.stop();
    final playbackEnded = Future.any<void>([
      audioPlayer.onPlayerComplete.first,
      audioPlayer.onPlayerStateChanged
          .firstWhere((state) =>
              state == PlayerState.completed || state == PlayerState.stopped)
          .then((_) {}),
    ]);
    await audioPlayer.play(
      BytesSource(audioBytes, mimeType: 'audio/mpeg'),
    );
    await playbackEnded.timeout(const Duration(seconds: 120), onTimeout: () {});
  }

  Future<void> speakWithDeviceVoice(String text, String language) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final fallbackTts = _fallbackTts ??= FlutterTts();
    await _audioPlayer?.stop();
    await fallbackTts.stop();
    await fallbackTts.awaitSpeakCompletion(true);
    await fallbackTts.setLanguage(_ttsLocaleForLanguage(language));
    await fallbackTts.setSpeechRate(0.46);
    await fallbackTts.setPitch(1.0);
    await fallbackTts.setVolume(1.0);
    await fallbackTts.speak(trimmedText);
  }

  Future<void> stopPlayback() async {
    await _audioPlayer?.stop();
    await _fallbackTts?.stop();
  }

  Future<void> dispose() async {
    await _speech.cancel();
    await cancelRecording();
    await _recorder.dispose();
    await stopPlayback();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
    _fallbackTts = null;
  }

  void _emitFinalResultIfNeeded() {
    final words = _lastWords.trim();
    if (_finalResultDelivered || words.isEmpty) {
      return;
    }
    _finalResultDelivered = true;
    _onFinalResult?.call(words);
  }

  bool get _shouldUseSahara {
    final provider = ttsProvider.trim().toLowerCase();
    if (provider == 'sahara') {
      return true;
    }
    if (provider == 'omnivoice' || provider == 'omni_voice') {
      return false;
    }
    return omnivoiceApiUrl.isEmpty && saharaTtsEdgeFunction.isNotEmpty;
  }

  /// Synthesizes speech via Sahara's TTS Generate endpoint, proxied through
  /// the sahara-tts edge function so SAHARA_API_KEY never reaches the client.
  /// Only English and Shona are supported - this must only be called for
  /// languages in the caller's voice-supported set (see
  /// _voiceSupportedLanguages in home_widget.dart). Sahara has no accent
  /// specifically for Shona-accented English or any of Rudo's other five
  /// Bantu languages, so English replies use the "zulu" accent as the
  /// closest available Southern African option.
  Future<Uint8List> _synthesizeSahara(
    String trimmedText,
    String language,
  ) async {
    final voiceLanguage = _saharaTtsLanguageCode(language);
    final voiceAccent = _saharaTtsAccent(language);
    if (voiceLanguage == null || voiceAccent == null) {
      throw StateError(
        'Sahara TTS has no voice for language "$language" - '
        'only english and shona are supported.',
      );
    }

    final response = await supabase.Supabase.instance.client.functions.invoke(
      saharaTtsEdgeFunction,
      body: {
        'text': trimmedText,
        'voice_language': voiceLanguage,
        'voice_accent': voiceAccent,
        'voice_gender': 'female',
        'output_audio_format': 'wav',
      },
    ).timeout(const Duration(seconds: 45));

    final data = response.data;
    if (data is Map) {
      final audioBase64 = data['audio_base64'];
      if (audioBase64 is String && audioBase64.isNotEmpty) {
        return base64Decode(audioBase64);
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        throw StateError(error);
      }
    }

    throw StateError('sahara-tts Edge Function did not return audio bytes.');
  }

  Future<Uint8List> _synthesizeOmniVoice(
    String trimmedText,
    String language,
  ) async {
    if (omnivoiceApiUrl.isEmpty) {
      throw StateError('OMNIVOICE_API_URL is not configured.');
    }

    final uri = Uri.parse(omnivoiceApiUrl);
    final isWaveSpeed = uri.host.contains('wavespeed.ai');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (omnivoiceApiKey.isNotEmpty)
          'Authorization': 'Bearer $omnivoiceApiKey',
      },
      body: jsonEncode(
        isWaveSpeed
            ? _waveSpeedBody(trimmedText, language)
            : _standardOmniVoiceBody(trimmedText, language),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OmniVoice TTS failed with ${response.statusCode}.');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.startsWith('audio/') ||
        contentType == 'application/octet-stream') {
      return response.bodyBytes;
    }

    return _audioFromJson(response.body);
  }

  Map<String, dynamic> _standardOmniVoiceBody(String text, String language) => {
        'model': 'omnivoice',
        'input': text,
        'voice': 'rudo_female_young_adult_warm',
        'response_format': 'mp3',
        'language': language,
        'voice_design': {
          'gender': 'female',
          'age': 'young_adult',
          'pitch': 'warm_medium',
          'style': 'calm_clear',
        },
      };

  Map<String, dynamic> _waveSpeedBody(String text, String language) => {
        'text': text,
        'language': language,
        'voice': {
          'gender': 'female',
          'age': 'young_adult',
          'pitch': 'warm_medium',
          'style': 'calm_clear',
        },
      };

  Uint8List _audioFromJson(String body) {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      throw StateError('OmniVoice response did not include audio.');
    }

    final audioBase64 = data['audio_base64'] ??
        data['audio'] ??
        data['data']?['audio_base64'] ??
        data['data']?['audio'];
    if (audioBase64 is String && audioBase64.isNotEmpty) {
      return base64Decode(audioBase64);
    }

    final audioUrl = data['url'] ??
        data['audio_url'] ??
        data['data']?['url'] ??
        data['data']?['audio_url'];
    if (audioUrl is String && audioUrl.isNotEmpty) {
      throw StateError('OmniVoice returned an audio URL instead of bytes.');
    }

    throw StateError('OmniVoice response did not include audio bytes.');
  }

  /// Sahara's voice_language code for TTS - confirmed only 'en' and 'sn'
  /// are supported (see Supported Languages And Accents). Null for
  /// anything else so callers can fail loudly instead of mis-synthesizing.
  String? _saharaTtsLanguageCode(String language) {
    return switch (language.toLowerCase()) {
      'english' => 'en',
      'shona' => 'sn',
      _ => null,
    };
  }

  /// Sahara's voice_accent for TTS. Shona has its own dedicated accent;
  /// English has no Zimbabwe/Zambia-specific or generic American/British
  /// accent option, so 'zulu' (Southern African) is used as the closest
  /// available fit - confirmed against Sahara's accent list.
  String? _saharaTtsAccent(String language) {
    return switch (language.toLowerCase()) {
      'english' => 'zulu',
      'shona' => 'shona',
      _ => null,
    };
  }

  String _localeForLanguage(String? language) {
    final value = (language ?? '').toLowerCase();
    return switch (value) {
      'shona' => 'sn_ZW',
      'ndebele' => 'nd_ZW',
      'tonga' => 'toi_ZM',
      'bemba' => 'bem_ZM',
      'lozi' => 'loz_ZM',
      'chinyanja' || 'nyanja' => 'ny_ZM',
      _ => 'en_US',
    };
  }

  String _ttsLocaleForLanguage(String language) {
    return switch (language.toLowerCase()) {
      'shona' => 'sn-ZW',
      'ndebele' => 'nd-ZW',
      'tonga' => 'toi-ZM',
      'bemba' => 'bem-ZM',
      'lozi' => 'loz-ZM',
      'chinyanja' || 'nyanja' => 'ny-ZM',
      _ => 'en-US',
    };
  }
}