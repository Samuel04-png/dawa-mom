import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Endian;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:dawa_mom/transcript_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dawa_mom/auth/supabase_auth/supabase_user_provider.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/domain/dawa_learning_content.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learning_detail_pages.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:dawa_mom/navbar/home/home_widget.dart' show AIChatModal;
import 'package:dawa_mom/services/voice_service.dart';

class ControlledVoice extends VoiceService {
  final playback = Completer<void>();
  int speakCalls = 0;
  int stops = 0;
  int listens = 0;
  int audioCalls = 0;
  ValueChanged<String>? finalResult;
  ValueChanged<String>? recognitionError;
  ValueChanged<String>? partialResult;
  String transcript = 'Help me prepare for a clinic visit.';
  bool speechFails = false;
  bool holdSpeech = false;
  Uint8List thinkingBytes = Uint8List(0);
  final speechPlayback = Completer<void>();
  @override
  Future<void> startListening(
      {String? language,
      ValueChanged<String>? onFinalResult,
      ValueChanged<String>? onPartialResult,
      ValueChanged<String>? onRecognitionError}) async {
    listens++;
    finalResult = onFinalResult;
    recognitionError = onRecognitionError;
    partialResult = onPartialResult;
  }

  @override
  Future<String> stopAndTranscribe() async => transcript;
  @override
  Future<Uint8List> synthesizeSpeech(String text, String language) async =>
      thinkingBytes;
  @override
  Future<void> cancelListening() async {}
  @override
  Future<void> playAudio(Uint8List bytes, {String mimeType = 'audio/mpeg'}) {
    audioCalls++;
    if (fail) return Future.error(StateError('synthetic playback failure'));
    return playback.future;
  }

  String? language;
  bool fail = false;
  @override
  Future<void> speakText(String text, String lang) {
    speakCalls++;
    language = lang;
    if (fail || speechFails)
      return Future.error(StateError('synthetic playback failure'));
    return holdSpeech ? speechPlayback.future : playback.future;
  }

  @override
  Future<void> stopPlayback() async {
    stops++;
    if (speakCalls > 0 && !speechPlayback.isCompleted)
      speechPlayback.complete();
    if (!playback.isCompleted) playback.complete();
  }

  @override
  Future<void> dispose() async {}
}

class LatencySpeechRecognizer extends SpeechToText {
  LatencySpeechRecognizer() : super.withMethodChannel();
  SpeechResultListener? resultListener;
  SpeechListenOptions? options;
  final pauses = <Duration>[];
  bool listening = false;
  @override
  Future<bool> initialize(
          {SpeechErrorListener? onError,
          SpeechStatusListener? onStatus,
          debugLogging = false,
          Duration finalTimeout = SpeechToText.defaultFinalTimeout,
          List<SpeechConfigOption>? options}) async =>
      true;
  @override
  Future<List<LocaleName>> locales() async => [LocaleName('en_US', 'English')];
  @override
  Future<void> listen(
      {SpeechResultListener? onResult,
      Duration? listenFor,
      Duration? pauseFor,
      String? localeId,
      SpeechSoundLevelChange? onSoundLevelChange,
      cancelOnError = false,
      partialResults = true,
      onDevice = false,
      ListenMode listenMode = ListenMode.confirmation,
      sampleRate = 0,
      SpeechListenOptions? listenOptions}) async {
    resultListener = onResult;
    options = listenOptions;
    listening = true;
  }

  @override
  void changePauseFor(Duration pauseFor) {
    pauses.add(pauseFor);
  }

  @override
  bool get isListening => listening;
  @override
  Future<void> cancel() async {
    listening = false;
  }

  @override
  Future<void> stop() async {
    listening = false;
  }

  void emit(String words, {bool finalResult = false}) {
    resultListener!(SpeechRecognitionResult.init(
        [SpeechRecognitionWords(words, [], 1.0)],
        finalResult ? ResultType.finalResult : ResultType.partial));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <Map<String, dynamic>>[];
  final rows = <Map<String, dynamic>>[];
  final ttsRequests = <Map<String, dynamic>>[];
  bool ttsFails = false;
  Completer<void>? chatGate;
  Completer<void>? historyGate;
  bool historyFails = false;
  int historyReads = 0;
  String responseMode = 'success';
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://127.0.0.1:54327',
      publishableKey: 'local-validation-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((req) async {
        debugPrint('LOCAL MOCK HTTP ${req.method} ${req.url.path}');
        if (req.url.path.endsWith('/sahara-tts')) {
          ttsRequests.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(
              jsonEncode(ttsFails
                  ? {'error': 'synthetic Mansa outage'}
                  : {
                      'audio_base64': base64Encode(
                          [82, 73, 70, 70, 0, 0, 0, 0, 87, 65, 86, 69])
                    }),
              ttsFails ? 502 : 200,
              request: req,
              headers: {'content-type': 'application/json'});
        }
        if (req.url.path.endsWith('/rudo-chat')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          requests.add(body);
          if (chatGate != null) await chatGate!.future;
          if (responseMode == 'error') {
            return http.Response(
                jsonEncode({'error': 'synthetic upstream unavailable'}), 502,
                request: req, headers: {'content-type': 'application/json'});
          }
          rows.addAll([
            {
              'id': 'user-1',
              'role': 'user',
              'content': body['message'],
              'created_at': '2026-10-28T10:00:00Z'
            },
            {
              'id': 'assistant-1',
              'role': 'assistant',
              'content':
                  'LOCAL TEST RESPONSE: bring your questions and records.',
              'created_at': '2026-10-28T10:00:01Z'
            },
          ]);
          return http.Response(
              jsonEncode({
                'session_id': 'synthetic-session',
                'reply': rows.last['content']
              }),
              200,
              request: req,
              headers: {'content-type': 'application/json'});
        }
        if (req.url.path.endsWith('/chat_messages')) {
          historyReads++;
          final snapshot = List<Map<String, dynamic>>.from(rows);
          if (historyGate != null) await historyGate!.future;
          if (historyFails) {
            return http.Response(
                jsonEncode(
                    {'code': '42501', 'message': 'synthetic history failure'}),
                403,
                request: req,
                headers: {'content-type': 'application/json'});
          }
          return http.Response(jsonEncode(snapshot), 200,
              request: req, headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200,
            request: req, headers: {'content-type': 'application/json'});
      }),
    );
    // Only suppress missing native plugin cleanup in the widget test process.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugin.csdcorp.com/speech_to_text'),
            (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (call) async => call.method == 'isRecording' ? false : null);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    rows.clear();
    responseMode = 'success';
    ttsRequests.clear();
    ttsFails = false;
    chatGate = null;
    historyGate = null;
    historyFails = false;
    historyReads = 0;
    currentUser = null;
  });
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(theme: DawaTheme.light(), home: Scaffold(body: page)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('catalog has nine unique ids and routes', () {
    expect(DawaLearningCatalog.items.length, 9);
    expect(DawaLearningCatalog.items.map((x) => x.id).toSet().length, 9);
    expect(DawaLearningCatalog.items.map((x) => x.route).toSet().length, 9);
  });
  testWidgets(
      'pregnancy guide completes and survives page/repository recreation',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await pumpPage(
        tester,
        DawaPregnancyGuideDetailPage(
            guideId: 'clinic-visit',
            repository: DawaLearningRepository(preferences: prefs)));
    expect(find.text('How to prepare for your clinic visit'), findsOneWidget);
    await tester.ensureVisible(find.text('Mark complete'));
    await tester.tap(find.text('Mark complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Completed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await pumpPage(
        tester,
        DawaPregnancyGuideDetailPage(
            guideId: 'clinic-visit',
            repository: DawaLearningRepository(preferences: prefs)));
    expect(find.text('Completed'), findsOneWidget);
    expect(
        (await DawaLearningRepository(preferences: prefs).load()).completedIds,
        contains('clinic-visit'));
  });
  testWidgets('stopping lesson early does not record completion',
      (tester) async {
    final voice = ControlledVoice();
    final prefs = await SharedPreferences.getInstance();
    final repo = DawaLearningRepository(preferences: prefs);
    await pumpPage(
        tester, DawaAudioLessonPage(voiceService: voice, repository: repo));
    await tester.tap(find.bySemanticsLabel('Play lesson'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(voice.audioCalls, 1);
    expect(
        (await repo.load()).completedIds, isNot(contains('pregnancy-basics')));
    await tester.tap(find.bySemanticsLabel('Stop lesson'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        (await repo.load()).completedIds, isNot(contains('pregnancy-basics')));
  });
  testWidgets('replay starts the bundled recording', (tester) async {
    final voice = ControlledVoice();
    await pumpPage(tester, DawaAudioLessonPage(voiceService: voice));
    await tester.tap(find.byTooltip('Replay from beginning'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(voice.audioCalls, 1);
    expect(voice.speakCalls, 0);
  });
  testWidgets('course playback failure preserves transcript without completion',
      (tester) async {
    final voice = ControlledVoice()..fail = true;
    final repo = DawaLearningRepository();
    await pumpPage(
        tester, DawaAudioLessonPage(voiceService: voice, repository: repo));
    await tester.tap(find.bySemanticsLabel('Play lesson'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.text(
            'Audio could not play. The full transcript is available below.'),
        findsOneWidget);
    expect(
        (await repo.load()).completedIds, isNot(contains('pregnancy-basics')));
  });
  testWidgets('Learn count refreshes after completed guide returns',
      (tester) async {
    final repo = DawaLearningRepository();
    final router = GoRouter(initialLocation: '/learn', routes: [
      GoRoute(
          path: '/learn', builder: (_, __) => DawaLearnPage(repository: repo)),
      GoRoute(
          path: '/learn/pregnancy/:guideId',
          builder: (_, state) => DawaPregnancyGuideDetailPage(
              guideId: state.pathParameters['guideId']!, repository: repo)),
    ]);
    addTearDown(router.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp.router(theme: DawaTheme.light(), routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('0 lessons'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('learning-search')), 'clinic');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Read now'));
    await tester.tap(find.text('Read now'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark complete'));
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();
    expect((await repo.load()).completedIds, contains('clinic-visit'));
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('0 lessons'), findsNothing);
    expect(find.text('1 lessons'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('typed chat local mocked response and payload (NOT live AI)',
      (tester) async {
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await tester.runAsync(() async {
      final probe = await Supabase.instance.client
          .from('chat_sessions')
          .select()
          .eq('profile_id', 'synthetic-user');
      debugPrint('LOCAL MOCK SESSION PROBE $probe');
    });
    await pumpPage(
        tester,
        const AIChatModal(
            userPhoneNumber: '', userName: 'Synthetic Runtime Test'));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump();
    await tester.enterText(find.byType(TextField),
        'What should I bring to my next antenatal visit?');
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Send'))
            .onPressed,
        isNotNull);
    await tester.tap(
        find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Send'));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(requests.length, 1);
    expect(requests.single['message'],
        'What should I bring to my next antenatal visit?');
    expect(find.text('LOCAL TEST RESPONSE: bring your questions and records.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('typed chat local mocked 502 becomes visible error (NOT live AI)',
      (tester) async {
    responseMode = 'error';
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await tester.runAsync(() async {
      final probe = await Supabase.instance.client
          .from('chat_sessions')
          .select()
          .eq('profile_id', 'synthetic-user');
      debugPrint('LOCAL MOCK SESSION PROBE $probe');
    });
    await pumpPage(
        tester,
        const AIChatModal(
            userPhoneNumber: '', userName: 'Synthetic Runtime Test'));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump();
    await tester.enterText(
        find.byType(TextField), 'Help me prepare for a clinic visit.');
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Send'))
            .onPressed,
        isNotNull);
    await tester.tap(
        find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Send'));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(
        find.text(
            'Rudo is having trouble reaching the assistant service. Please try again.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('natural end of bundled recording saves completion and reopens',
      (tester) async {
    final voice = ControlledVoice();
    final repo = DawaLearningRepository();
    await pumpPage(
        tester, DawaAudioLessonPage(voiceService: voice, repository: repo));
    await tester.tap(find.bySemanticsLabel('Play lesson'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(voice.audioCalls, 1);
    voice.playback.complete();
    await tester.pumpAndSettle();
    expect((await repo.load()).completedIds, contains('pregnancy-basics'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect((await DawaLearningRepository().load()).completedIds,
        contains('pregnancy-basics'));
  });
  testWidgets(
      'live partial transcript waits for turn end, sends once without a popup, speaks and resumes',
      (tester) async {
    final voice = ControlledVoice()..playback.complete();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    expect(voice.listens, 1);
    expect(requests, isEmpty);
    voice.partialResult!('Help me prepare');
    await tester.pump();
    expect(find.text('Help me prepare'), findsOneWidget);
    expect(requests, isEmpty);
    final finish = voice.finalResult!;
    finish(voice.transcript);
    finish(voice.transcript);
    await tester.pump();
    expect(find.text('Check what I heard'), findsNothing);

    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(requests.single['message'], 'Help me prepare for a clinic visit.');
    expect(requests.single.containsKey('audio_base64'), isFalse);
    expect(voice.speakCalls, 1);
    expect(voice.listens, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'review cancel sends nothing; empty text cannot send; re-record is explicit',
      (tester) async {
    TranscriptReviewResult? result;
    await pumpPage(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  result = await showTranscriptReview(context,
                      initialText: 'Original words');
                },
                child: const Text('Review'))));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  ');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'))
            .onPressed,
        isNull);
    await tester.tap(find.text('Record again'));
    await tester.pumpAndSettle();
    expect(result?.action, TranscriptReviewAction.rerecord);
    result = null;
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
  test('all five bundled lesson recordings are present and nonempty', () async {
    for (final language in ['english', 'nyanja', 'bemba', 'shona', 'ndebele']) {
      final bytes = await rootBundle
          .load('assets/audios/lessons/pregnancy_basics_$language.mp3');
      expect(bytes.lengthInBytes, greaterThan(1000));
    }
  });
  testWidgets(
      'Tonga without a bundled clip uses the Tonga transcript for synthesis',
      (tester) async {
    final voice = ControlledVoice();
    await pumpPage(tester, DawaAudioLessonPage(voiceService: voice));
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tonga'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tonga'));
    await tester.pump();
    await tester.ensureVisible(find.bySemanticsLabel('Play lesson'));
    await tester.tap(find.bySemanticsLabel('Play lesson'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(voice.audioCalls, 0);
    expect(voice.speakCalls, 1);
    expect(voice.language, 'Tonga');
  });
  test('Chrome can request a language before its locale list exists', () {
    expect(
        VoiceService.recognitionLocale(
            requestedLocale: 'en_US', availableLocales: [], isWeb: true),
        'en_US');
    expect(
        VoiceService.recognitionLocale(
            requestedLocale: 'sn_ZW', availableLocales: ['en_US'], isWeb: true),
        'sn_ZW');
  });
  test(
      'native recognition prefers exact locale and rejects unavailable languages',
      () {
    expect(
        VoiceService.recognitionLocale(
            requestedLocale: 'en_US',
            availableLocales: ['en_GB', 'en-US'],
            isWeb: false),
        'en-US');
    expect(
        VoiceService.recognitionLocale(
            requestedLocale: 'en_US',
            availableLocales: ['en_GB'],
            isWeb: false),
        'en_GB');
    expect(
        () => VoiceService.recognitionLocale(
            requestedLocale: 'sn_ZW',
            availableLocales: ['en_US'],
            isWeb: false),
        throwsStateError);
  });
  testWidgets(
      'browser recognition error leaves a retryable mic without sending a message',
      (tester) async {
    final voice = ControlledVoice();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var cycle = 0; cycle < 4; cycle++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.recognitionError!('network');
    await tester.pump();
    expect(find.text('Tap the mic to speak'), findsOneWidget);
    expect(
        find.text(
            'Speech recognition could not connect. Check your internet connection, then try again.'),
        findsWidgets);
    expect(requests, isEmpty);
    expect(voice.listens, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  test(
      'cloud speech sends Tari Mansa language contract for supported languages',
      () async {
    final service = VoiceService();
    for (final language in ['English', 'Shona', 'Bemba', 'Nyanja', 'Ndebele']) {
      final bytes = await service.synthesizeSpeech('Hello.', language);
      expect(bytes, isNotEmpty);
    }
    expect(ttsRequests.map((r) => r['language']).toList(),
        ['english', 'shona', 'bemba', 'chinyanja', 'ndebele']);
    expect(
        ttsRequests.every(
            (r) => r.keys.toSet().difference({'text', 'language'}).isEmpty),
        isTrue);
  });
  test('cloud failure is surfaced instead of switching to the device voice',
      () async {
    ttsFails = true;
    await expectLater(VoiceService().speakText('Hello.', 'english'),
        throwsA(isA<FunctionException>()));
  });
  test('streamed WAV headers are repaired without altering MP3 bytes', () {
    final wav = Uint8List(48);
    wav.setRange(0, 4, 'RIFF'.codeUnits);
    wav.setRange(8, 12, 'WAVE'.codeUnits);
    wav.setRange(12, 16, 'fmt '.codeUnits);
    final data = ByteData.sublistView(wav);
    data.setUint32(4, 0xffffffff, Endian.little);
    data.setUint32(16, 16, Endian.little);
    wav.setRange(36, 40, 'data'.codeUnits);
    data.setUint32(40, 0xffffffff, Endian.little);
    final repaired = VoiceService.repairWavHeader(wav);
    final fixed = ByteData.sublistView(repaired);
    expect(fixed.getUint32(4, Endian.little), 40);
    expect(fixed.getUint32(40, Endian.little), 4);
    expect(data.getUint32(40, Endian.little), 0xffffffff);
    expect(VoiceService.audioMimeType(repaired), 'audio/wav');
    final mp3 = Uint8List.fromList([73, 68, 51, 0]);
    expect(VoiceService.repairWavHeader(mp3), same(mp3));
    expect(VoiceService.audioMimeType(mp3), 'audio/mpeg');
  });
  testWidgets(
      'ending voice during a spoken reply never restarts the microphone',
      (tester) async {
    final voice = ControlledVoice()..holdSpeech = true;
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(voice.speakCalls, 1);
    await tester.tap(find.text('End voice mode'));
    await tester.pump();
    if (!voice.playback.isCompleted) voice.playback.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(voice.listens, 1);
    expect(requests.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'cloud voice failure keeps the reply readable and stops the conversation loop',
      (tester) async {
    final voice = ControlledVoice()..speechFails = true;
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.text(
            'Rudo replied, but the selected voice could not play. Return to typing to read the reply.'),
        findsOneWidget);
    expect(voice.listens, 1);
    expect(requests.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'slow reply shows truthful thinking feedback and one optional warm acknowledgement',
      (tester) async {
    chatGate = Completer<void>();
    final voice = ControlledVoice()
      ..thinkingBytes = Uint8List.fromList([73, 68, 51, 0]);
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    await tester.pump();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Thinking…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(voice.audioCalls, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Putting your reply together…'), findsOneWidget);
    expect(voice.audioCalls, 1);
    expect(requests.length, 1);
    chatGate!.complete();
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    expect(voice.speakCalls, 1);
    expect(voice.listens, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('ending listening ignores a late final recognition result',
      (tester) async {
    final voice = ControlledVoice();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    final lateResult = voice.finalResult!;
    await tester.tap(find.text('End voice mode'));
    await tester.pump();
    lateResult(voice.transcript);
    await tester.pump(const Duration(seconds: 1));
    expect(requests, isEmpty);
    expect(voice.speakCalls, 0);
    expect(voice.listens, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  test(
      'short silence deadline begins only after speech and partials remain unsent',
      () async {
    final recognizer = LatencySpeechRecognizer();
    final service = VoiceService(speechRecognizer: recognizer);
    final sent = <String>[];
    final partials = <String>[];
    await service.startListening(
        language: 'english',
        onFinalResult: sent.add,
        onPartialResult: partials.add);
    expect(recognizer.options?.pauseFor, const Duration(seconds: 8));
    expect(recognizer.pauses, isEmpty);
    recognizer.emit('');
    expect(recognizer.pauses, isEmpty);
    expect(sent, isEmpty);
    recognizer.emit('Hello');
    expect(recognizer.pauses, [const Duration(milliseconds: 1200)]);
    expect(partials.last, 'Hello');
    expect(sent, isEmpty);
    recognizer.emit('Hello Rudo');
    expect(recognizer.pauses.length, 1);
    expect(sent, isEmpty);
    recognizer.emit('Hello Rudo', finalResult: true);
    recognizer.emit('Hello Rudo', finalResult: true);
    expect(sent, ['Hello Rudo']);
    await service.cancelListening();
    await service.startListening(language: 'english', onFinalResult: sent.add);
    recognizer.emit('Another turn');
    expect(recognizer.pauses.length, 2);
    await service.cancelListening();
  });
  testWidgets('voice begins while persisted history reload is still waiting',
      (tester) async {
    historyGate = Completer<void>();
    final voice = ControlledVoice();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    expect(historyReads, 1);
    expect(historyGate!.isCompleted, isFalse);
    expect(voice.speakCalls, 1,
        reason: 'Speech must not wait for database history.');
    historyGate!.complete();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'history outage cannot turn an already received voice reply into an AI failure',
      (tester) async {
    historyFails = true;
    final voice = ControlledVoice();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    expect(voice.speakCalls, 1);
    expect(voice.listens, 2);
    expect(requests.length, 1);
    await tester.tap(find.text('End voice mode'));
    await tester.pump();
    expect(find.text('LOCAL TEST RESPONSE: bring your questions and records.'),
        findsOneWidget);
    expect(
        find.text(
            'Rudo is having trouble reaching the assistant service. Please try again.'),
        findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('late history refresh cannot erase a newer outgoing message',
      (tester) async {
    historyGate = Completer<void>();
    final voice = ControlledVoice();
    currentUser = DawaMomSupabaseUser(User(
        id: 'synthetic-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-28T00:00:00Z'));
    await pumpPage(
        tester,
        AIChatModal(
            userPhoneNumber: '',
            userName: 'Synthetic Test',
            voiceService: voice));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.tap(find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Start voice'));
    await tester.pump();
    voice.finalResult!(voice.transcript);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    expect(historyReads, 1);
    chatGate = Completer<void>();
    await tester.tap(find.text('End voice mode'));
    await tester.pump();
    await tester.enterText(
        find.byType(TextField), 'A newer synthetic message.');
    await tester.pump();
    await tester.tap(
        find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Send'));
    await tester.pump();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    historyGate!.complete();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
    expect(find.text('A newer synthetic message.'), findsOneWidget);
    chatGate!.complete();
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)));
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
