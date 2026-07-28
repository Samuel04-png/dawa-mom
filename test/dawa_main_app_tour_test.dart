import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/onboarding/dawa_main_app_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tour completion is versioned, local-first, and only shown once',
      () async {
    final service = MainAppTourService(userIdOverride: 'member-1');

    expect(await service.shouldShow(), isTrue);
    await service.complete();
    expect(await service.shouldShow(), isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(
        MainAppTourService.completedVersionKey('member-1'),
      ),
      MainAppTourService.currentVersion,
    );
    expect(
      preferences.getString(MainAppTourService.completedAtKey('member-1')),
      isNotEmpty,
    );
  });

  test('skip persists completion while replay starts a temporary session',
      () async {
    final service = MainAppTourService(userIdOverride: 'member-2');
    final controller = DawaMainAppTourController(service: service);

    controller.start();
    expect(controller.active, isTrue);
    await controller.skip();
    expect(controller.active, isFalse);
    expect(await service.shouldShow(), isFalse);

    controller.start(replay: true);
    expect(controller.active, isTrue);
    expect(controller.index, 0);
    expect(controller.step.target, DawaMainAppTourTarget.homeJourney);
    await controller.finish();
    controller.dispose();
  });

  test('tour steps select the correct main navigation tabs', () {
    expect(
      dawaMainAppTourSteps
          .map((step) => dawaMainAppTourTabFor(step.target))
          .toList(),
      [0, 1, 2, 3, 0, 0, 4],
    );
  });

  testWidgets('Back, Next, Skip and accessible progress work', (tester) async {
    final service = MainAppTourService(userIdOverride: 'member-3');
    final selectedTargets = <DawaMainAppTourTarget>[];
    final controller = DawaMainAppTourController(
      service: service,
      onStepChanged: (step) => selectedTargets.add(step.target),
    );
    final targetKey = GlobalKey();
    controller.start();

    await tester.pumpWidget(
      _tourHost(
        controller: controller,
        targetKey: targetKey,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 7'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'1 of 7.*Your health journey', dotAll: true),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 of 7'), findsOneWidget);
    expect(selectedTargets.last, DawaMainAppTourTarget.track);

    await tester.tap(find.byKey(const ValueKey('tour-back')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 7'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tour-skip')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('dawa-main-app-tour-overlay')), findsNothing);
    expect(await service.shouldShow(), isFalse);
    controller.dispose();
  });

  testWidgets('missing target falls back safely without crashing',
      (tester) async {
    final controller = DawaMainAppTourController(
      service: MainAppTourService(userIdOverride: 'member-4'),
    )..start();

    await tester.pumpWidget(
      _tourHost(
        controller: controller,
        targetKey: GlobalKey(),
        includeTarget: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Your health journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
      'tour remains usable at target sizes, scaled text and reduced motion',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final configuration in const [
      (Size(360, 800), 1.3, false),
      (Size(412, 915), 1.5, true),
    ]) {
      tester.view.physicalSize = configuration.$1;
      final controller = DawaMainAppTourController(
        service: MainAppTourService(
          userIdOverride: 'member-${configuration.$1.width}',
        ),
      )..start();
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        _tourHost(
          controller: controller,
          targetKey: targetKey,
          textScale: configuration.$2,
          disableAnimations: configuration.$3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your health journey'), findsOneWidget);
      expect(find.byKey(const ValueKey('tour-next')), findsOneWidget);
      expect(find.byKey(const ValueKey('tour-skip')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });
}

Widget _tourHost({
  required DawaMainAppTourController controller,
  required GlobalKey targetKey,
  bool includeTarget = true,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  final targetKeys = <DawaMainAppTourTarget, GlobalKey>{
    if (includeTarget)
      for (final target in DawaMainAppTourTarget.values) target: targetKey,
  };
  return MaterialApp(
    theme: DawaTheme.light(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              if (includeTarget)
                Center(
                  child: SizedBox(
                    key: targetKey,
                    width: 120,
                    height: 60,
                    child: const Text('Tour target'),
                  ),
                ),
              Positioned.fill(
                child: DawaMainAppTourOverlay(
                  controller: controller,
                  targetKeys: targetKeys,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
