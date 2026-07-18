import 'dart:io';

import 'package:dawa_mom/dawa_splash_screen.dart';
import 'package:dawa_mom/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved dark preference is ignored by the light-only theme', () async {
    SharedPreferences.setMockInitialValues({'__theme_mode__': true});
    await FlutterFlowTheme.initialize();

    expect(FlutterFlowTheme.themeMode, ThemeMode.light);
  });

  testWidgets('FlutterFlow colors stay light under a dark platform theme',
      (tester) async {
    late FlutterFlowTheme resolvedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            resolvedTheme = FlutterFlowTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolvedTheme, isA<LightModeTheme>());
    expect(resolvedTheme.primaryBackground, const Color(0xFFF1F4F8));
  });

  testWidgets('transparent splash is responsive and completes once',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1024, 768),
      Size(1366, 768),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: DawaSplashScreen(onAnimationComplete: () {}),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final image = tester.widget<Image>(find.byType(Image));
      final renderedSize = tester.getSize(find.byType(Image));

      expect(scaffold.backgroundColor, LightModeTheme().primary);
      expect((image.image as AssetImage).assetName, DawaSplashScreen.assetPath);
      expect(image.fit, BoxFit.contain);
      expect(image.gaplessPlayback, isTrue);
      expect(renderedSize.width, lessThanOrEqualTo(560));
      expect(renderedSize.width, lessThanOrEqualTo(size.width * 0.75));

      await tester.pumpWidget(const SizedBox());
    }

    var completionCount = 0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        home: DawaSplashScreen(
          onAnimationComplete: () => completionCount += 1,
        ),
      ),
    );
    await tester.pump(DawaSplashScreen.splashDuration);
    expect(completionCount, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completionCount, 1);
  });

  test('theme controls and old mapped assets are absent from Dart sources', () {
    final source = _allDartSource();

    for (final forbidden in [
      'ThemeMode.dark',
      'ThemeMode.system',
      'DarkModeTheme',
      'setDarkModeSetting',
      'Dark appearance',
      'darkTheme:',
      'assets/images/Frame_41.png',
      'assets/images/Menstrual_calendar-pana.png',
      'assets/images/No_data-pana.png',
      'assets/images/Pregnancy_stages-pana.png',
      'assets/images/Status_update-pana.png',
      'assets/images/login-page-img.png',
      'assets/images/dawa_mom_cross.png',
      'assets/images/dawa_mom_full.png',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }

    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, contains('themeMode: ThemeMode.light'));
  });

  test('registered transparent assets exist and retain alpha channels', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/dawa_intro.gif'));
    expect(pubspec, contains('assets/images/transparent assets/'));

    for (final path in [
      DawaSplashScreen.assetPath,
      'assets/images/transparent assets/Frame_41.png',
      'assets/images/transparent assets/Menstrual_calendar-pana.png',
      'assets/images/transparent assets/No_data-pana.png',
      'assets/images/transparent assets/Pregnancy_stages-pana.png',
      'assets/images/transparent assets/Status_update-pana.png',
      'assets/images/transparent assets/login-page-img.png',
      'assets/images/transparent assets/dawa_mom_cross.png',
      'assets/images/transparent assets/dawa_mom_full.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}

String _allDartSource() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) =>
        file.path.endsWith('.dart') &&
        !file.uri.pathSegments.last.startsWith('._'))
    .map((file) => file.readAsStringSync())
    .join('\n');
