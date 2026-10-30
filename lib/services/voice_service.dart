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

// Raw recording remains available for clients with an audio-capable backend.
// The current chat screen uses device recognition and automatic turn completion instead.

class VoiceService {
  VoiceService({
    AudioPlayer? audioPlayer,
    FlutterTts? fallbackTts,
    AudioRecorder? recorder,
    SpeechToText? speechRecognizer,
  })  : _audioPlayer = audioPlayer,
        _fallbackTts = fallbackTts,
        _recorder = recorder ?? AudioRecorder(),
        _speech = speechRecognizer ?? SpeechToText();

  static const Set<String> mansaTtsLanguages = {
    'english',
    'shona',
    'bemba',
    'chinyanja',
    'ndebele',
  };

  static const String ttsProvider = String.fromEnvironment('TTS_PROVIDER');
  static const String saharaTtsEdgeFunction = String.fromEnvironment(
    'SAHARA_TTS_EDGE_FUNCTION',
    defaultValue: 'sahara-tts',
  );

  static const String omnivoiceApiUrl =
      String.fromEnvironment('OMNIVOICE_API_URL');
  static const String omnivoiceApiKey =
      String.fromEnvironment('OMNIVOICE_API_KEY');

  static String get recordingMimeType => kIsWeb ? 'audio/wav' : 'audio/mp4';
  static String get recordingExtension => kIsWeb ? 'wav' : 'm4a';

  static const Duration turnPause = Duration(milliseconds: 1200);
  final SpeechToText _speech;
  bool _shortPauseEnabled = false;
  final Stopwatch _recognitionClock = Stopwatch();
  int? _lastPartialMs;
  final AudioRecorder _recorder;
  AudioPlayer? _audioPlayer;
  FlutterTts? _fallbackTts;
  String _lastWords = '';
  bool _speechReady = false;
  bool _finalResultDelivered = false;
  ValueChanged<String>? _onFinalResult;
  ValueChanged<String>? _onPartialResult;
  ValueChanged<String>? _onRecognitionError;
  String? _recordingPath;
  int _playbackEpoch = 0;

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission was not granted.');
    }

    if (kIsWeb) {
      // No filesystem on web. The recorder returns a blob URL on stop().
      // AAC isn't supported by browsers; WAV is the safest for server-side STT.
      _recordingPath = null;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: '',
      );
      return;
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

    if (kIsWeb) {
      // On web, resolvedPath is a blob: URL, not a file path.
      final response = await http.get(Uri.parse(resolvedPath));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
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
    ValueChanged<String>? onRecognitionError,
  }) async {
    _lastWords = '';
    _shortPauseEnabled = false;
    _lastPartialMs = null;
    _recognitionClock
      ..reset()
      ..start();
    _finalResultDelivered = false;
    _onFinalResult = onFinalResult;
    _onPartialResult = onPartialResult;
    _onRecognitionError = onRecognitionError;
    _speechReady = _speechReady ||
        await _speech.initialize(
          onError: (error) {
            debugPrint('Speech recognition error: $error');
            _onRecognitionError?.call(error.errorMsg);
          },
          onStatus: (status) {
            debugPrint('Speech recognition status: $status');
            if (status == 'done' || status == 'notListening') {
              _emitFinalResultIfNeeded();
            } else if (status == 'doneNoResult' && _lastWords.trim().isEmpty) {
              _onRecognitionError?.call('no-speech');
            }
          },
        );

    if (!_speechReady) {
      throw StateError('Speech recognition is not available on this device.');
    }

    final requestedLocale = _localeForLanguage(language);
    // The browser plugin exposes only the current recognition language,
    // often empty before listen(). It cannot enumerate supported languages.
    final locales = kIsWeb
        ? <String>[]
        : (await _speech.locales()).map((locale) => locale.localeId).toList();
    final locale = recognitionLocale(
        requestedLocale: requestedLocale,
        availableLocales: locales,
        isWeb: kIsWeb);
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: locale.replaceAll('_', '-'),
        listenFor: const Duration(seconds: 45),
        // Allow time to begin speaking; tighten the pause after the first words.
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords.trim();
        if (_lastWords.isNotEmpty && !_shortPauseEnabled) {
          _shortPauseEnabled = true;
          _speech.changePauseFor(turnPause);
        }
        if (result.finalResult) {
          _emitFinalResultIfNeeded();
        } else {
          _lastPartialMs = _recognitionClock.elapsedMilliseconds;
          _onPartialResult?.call(_lastWords);
        }
      },
    );
  }

  @visibleForTesting
  static String recognitionLocale({
    required String requestedLocale,
    required Iterable<String> availableLocales,
    required bool isWeb,
  }) {
    if (isWeb) return requestedLocale;
    String normalized(String value) => value.replaceAll('_', '-').toLowerCase();
    final locales = availableLocales.toList();
    for (final locale in locales) {
      if (normalized(locale) == normalized(requestedLocale)) return locale;
    }
    for (final locale in locales) {
      if (normalized(locale).split('-').first ==
          normalized(requestedLocale).split('-').first) return locale;
    }
    throw StateError(
        'Speech recognition is unavailable for this language on this device.');
  }

  Future<void> cancelListening() async {
    _onFinalResult = null;
    _onPartialResult = null;
    _onRecognitionError = null;
    await _speech.cancel();
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

    if (_shouldUseEdgeTts) {
      if (ttsProvider.trim().toLowerCase() == 'sahara') {
        return _synthesizeSahara(trimmedText, language);
      }
      return _synthesizeMansa(trimmedText, language);
    }

    return _synthesizeOmniVoice(trimmedText, language);
  }

  Future<void> speakText(String text, String language) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final epoch = _playbackEpoch;
    final generationTimer = Stopwatch()..start();
    final audioBytes = await synthesizeSpeech(trimmedText, language);
    debugPrint(
        '[Rudo timing] tts_generation_ms=${generationTimer.elapsedMilliseconds}');
    if (epoch != _playbackEpoch) return;
    // Provider errors are surfaced to the caller. Do not silently substitute
    // a different device voice for the selected cloud voice.
    await playAudio(audioBytes, mimeType: audioMimeType(audioBytes));
  }

  Future<void> playAudio(
    Uint8List audioBytes, {
    String mimeType = 'audio/mpeg',
  }) async {
    if (audioBytes.isEmpty) {
      return;
    }
    final epoch = ++_playbackEpoch;
    final playbackTimer = Stopwatch()..start();
    final audioPlayer = _audioPlayer ??= AudioPlayer();
    await audioPlayer.stop();
    if (epoch != _playbackEpoch) return;
    audioBytes = repairWavHeader(audioBytes);
    if (_looksLikeWav(audioBytes)) mimeType = 'audio/wav';
    final playbackEnded = Completer<void>();
    void completePlayback() {
      if (!playbackEnded.isCompleted) playbackEnded.complete();
    }

    void failPlayback(Object error, StackTrace stack) {
      if (!playbackEnded.isCompleted) playbackEnded.completeError(error, stack);
    }

    final completedSubscription = audioPlayer.onPlayerComplete
        .listen((_) => completePlayback(), onError: failPlayback);
    final stateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped)
        completePlayback();
    }, onError: failPlayback);
    File? temporaryAudio;
    try {
      Source source = BytesSource(audioBytes, mimeType: mimeType);
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        final extension = mimeType == 'audio/wav' ? 'wav' : 'mp3';
        temporaryAudio = File(
            '${directory.path}/rudo_playback_${DateTime.now().microsecondsSinceEpoch}.$extension');
        await temporaryAudio.writeAsBytes(audioBytes);
        source = DeviceFileSource(temporaryAudio.path, mimeType: mimeType);
      }
      if (epoch != _playbackEpoch) return;
      await audioPlayer.play(source);
      debugPrint(
          '[Rudo timing] playback_command_ms=${playbackTimer.elapsedMilliseconds}');
      await playbackEnded.future.timeout(const Duration(minutes: 3));
    } finally {
      await completedSubscription.cancel();
      await stateSubscription.cancel();
      if (temporaryAudio != null && await temporaryAudio.exists()) {
        await temporaryAudio.delete();
      }
    }
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
    _playbackEpoch++;
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
    final partialMs = _lastPartialMs;
    if (partialMs != null) {
      debugPrint(
          '[Rudo timing] last_partial_to_final_ms=${_recognitionClock.elapsedMilliseconds - partialMs}');
    }
    _onFinalResult?.call(words);
  }

  bool get _shouldUseEdgeTts {
    final provider = ttsProvider.trim().toLowerCase();
    if (provider == 'sahara' || provider == 'mansa') {
      return true;
    }
    if (provider == 'omnivoice' || provider == 'omni_voice') {
      return false;
    }
    return omnivoiceApiUrl.isEmpty && saharaTtsEdgeFunction.isNotEmpty;
  }

  /// Matches Tari's deployed Mansa function, still named sahara-tts.
  Future<Uint8List> _synthesizeMansa(
    String trimmedText,
    String language,
  ) async {
    final mansaLanguage = _mansaLanguageKey(language);
    if (mansaLanguage == null) {
      throw StateError(
        'Mansa TTS has no voice for language "$language" - '
        'supported: ${mansaTtsLanguages.join(', ')}.',
      );
    }

    final response = await supabase.Supabase.instance.client.functions.invoke(
      saharaTtsEdgeFunction,
      body: {
        'text': trimmedText,
        'language': mansaLanguage,
      },
    ).timeout(const Duration(seconds: 45));

    final data = response.data;
    if (data is Map) {
      final audioBase64 = data['audio_base64'];
      if (audioBase64 is String && audioBase64.isNotEmpty) {
        final bytes = base64Decode(audioBase64);
        debugPrint(
            'Cloud speech generated: ${bytes.length} bytes (${audioMimeType(bytes)})');
        return bytes;
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        throw StateError(error);
      }
    }

    throw StateError(
      '$saharaTtsEdgeFunction Edge Function did not return audio bytes.',
    );
  }

  /// Synthesizes speech via Sahara's TTS Generate endpoint, proxied through
  /// the sahara-tts edge function so SAHARA_API_KEY never reaches the client.
  /// Only English and Shona are supported - this used only when TTS_PROVIDER=sahara is explicitly selected. Sahara has no accent
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

  /// Normalizes app language names ("Nyanja", "chichewa", "sn", ...) to the
  /// key the Mansa edge function expects, or null if Mansa has no voice.
  String? _mansaLanguageKey(String language) {
    final key = language.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    final normalized = switch (key) {
      'en' => 'english',
      'sn' => 'shona',
      'nd' || 'nde' => 'ndebele',
      'bem' => 'bemba',
      'ny' || 'nya' || 'nyanja' || 'chichewa' => 'chinyanja',
      _ => key,
    };
    return mansaTtsLanguages.contains(normalized) ? normalized : null;
  }

  /// Cheap sniff so the player gets the right mime hint: RIFF = WAV,
  /// ID3 / 0xFF 0xFB = MP3 (OmniVoice path). Defaults to WAV.
  static String audioMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }
    return 'audio/wav';
  }

  static bool _looksLikeWav(Uint8List b) =>
      b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WAVE';

  /// Rewrites the RIFF and data chunk sizes to match the real byte count.
  /// Streamed WAVs often declare 0 or 0xFFFFFFFF, which Android rejects.
  static Uint8List repairWavHeader(Uint8List b) {
    if (!_looksLikeWav(b)) return b;
    final out = Uint8List.fromList(b);
    final v = ByteData.sublistView(out);
    v.setUint32(4, out.length - 8, Endian.little);
    var off = 12;
    while (off + 8 <= out.length) {
      final id = String.fromCharCodes(out.sublist(off, off + 4));
      final size = v.getUint32(off + 4, Endian.little);
      if (id == 'data') {
        final remaining = out.length - (off + 8);
        if (size == 0 || size > remaining) {
          v.setUint32(off + 4, remaining, Endian.little);
        }
        break;
      }
      off += 8 + size + (size % 2);
    }
    return out;
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
