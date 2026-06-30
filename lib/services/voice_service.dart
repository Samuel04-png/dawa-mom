import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class VoiceService {
  VoiceService({AudioPlayer? audioPlayer, FlutterTts? fallbackTts})
      : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _fallbackTts = fallbackTts ?? FlutterTts();

  static const String ttsProvider = String.fromEnvironment('TTS_PROVIDER');
  static const String elevenLabsEdgeFunction = String.fromEnvironment(
    'ELEVENLABS_EDGE_FUNCTION',
    defaultValue: 'elevenlabs-tts',
  );
  static const String elevenLabsVoiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: 'EXAVITQu4vr4xnSDxMaL',
  );
  static const String elevenLabsModelId = String.fromEnvironment(
    'ELEVENLABS_MODEL_ID',
    defaultValue: 'eleven_multilingual_v2',
  );

  static const String omnivoiceApiUrl =
      String.fromEnvironment('OMNIVOICE_API_URL');
  static const String omnivoiceApiKey =
      String.fromEnvironment('OMNIVOICE_API_KEY');

  final SpeechToText _speech = SpeechToText();
  final AudioPlayer _audioPlayer;
  final FlutterTts _fallbackTts;
  String _lastWords = '';
  bool _speechReady = false;
  bool _finalResultDelivered = false;
  ValueChanged<String>? _onFinalResult;
  ValueChanged<String>? _onPartialResult;

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
      localeId: _localeForLanguage(language),
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
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

    if (_shouldUseElevenLabs) {
      return _synthesizeElevenLabs(trimmedText, language);
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
    await _audioPlayer.stop();
    final playbackEnded = Future.any<void>([
      _audioPlayer.onPlayerComplete.first,
      _audioPlayer.onPlayerStateChanged
          .firstWhere((state) =>
              state == PlayerState.completed || state == PlayerState.stopped)
          .then((_) {}),
    ]);
    await _audioPlayer.play(
      BytesSource(audioBytes, mimeType: 'audio/mpeg'),
    );
    await playbackEnded.timeout(const Duration(seconds: 120), onTimeout: () {});
  }

  Future<void> speakWithDeviceVoice(String text, String language) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    await _audioPlayer.stop();
    await _fallbackTts.stop();
    await _fallbackTts.awaitSpeakCompletion(true);
    await _fallbackTts.setLanguage(_ttsLocaleForLanguage(language));
    await _fallbackTts.setSpeechRate(0.46);
    await _fallbackTts.setPitch(1.0);
    await _fallbackTts.setVolume(1.0);
    await _fallbackTts.speak(trimmedText);
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    await _fallbackTts.stop();
  }

  Future<void> dispose() async {
    await _speech.cancel();
    await stopPlayback();
    await _audioPlayer.dispose();
  }

  void _emitFinalResultIfNeeded() {
    final words = _lastWords.trim();
    if (_finalResultDelivered || words.isEmpty) {
      return;
    }
    _finalResultDelivered = true;
    _onFinalResult?.call(words);
  }

  bool get _shouldUseElevenLabs {
    final provider = ttsProvider.trim().toLowerCase();
    if (provider == 'elevenlabs' || provider == 'eleven_labs') {
      return true;
    }
    if (provider == 'omnivoice' || provider == 'omni_voice') {
      return false;
    }
    return omnivoiceApiUrl.isEmpty && elevenLabsEdgeFunction.isNotEmpty;
  }

  Future<Uint8List> _synthesizeElevenLabs(
    String trimmedText,
    String language,
  ) async {
    if (elevenLabsEdgeFunction.isEmpty) {
      throw StateError('ELEVENLABS_EDGE_FUNCTION is not configured.');
    }

    final languageCode = _elevenLabsLanguageCode(language);
    final response = await supabase.Supabase.instance.client.functions.invoke(
      elevenLabsEdgeFunction,
      body: {
        'text': trimmedText,
        'voice_id': elevenLabsVoiceId,
        'model_id': elevenLabsModelId,
        if (languageCode != null) 'language_code': languageCode,
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

    throw StateError('ElevenLabs Edge Function did not return audio bytes.');
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
            : _openAiCompatibleBody(trimmedText, language),
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

  Map<String, dynamic> _openAiCompatibleBody(String text, String language) => {
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

  String? _elevenLabsLanguageCode(String language) {
    return switch (language.toLowerCase()) {
      'english' => 'en',
      'shona' => 'sn',
      'ndebele' => 'nd',
      'chinyanja' || 'nyanja' => 'ny',
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
