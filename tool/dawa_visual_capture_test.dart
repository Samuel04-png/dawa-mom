import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learning_detail_pages.dart';
import 'package:dawa_mom/features/preferences/dawa_language_sheet.dart';
import 'package:dawa_mom/features/preferences/dawa_user_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _captureKey = ValueKey('visual-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
    await loader.load();
  });

  setUp(() {
    // This one-off render harness deliberately uses an isolated preferences
    // store so visual captures do not depend on a developer's local state.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture welcome', (tester) async {
    await _pump(tester, const DawaWelcomePage());
    await _capture(tester, 'welcome.png');
  });

  testWidgets('capture registration', (tester) async {
    await _pump(tester, const DawaRegistrationPage());
    await _capture(tester, 'registration.png');
  });

  testWidgets('capture learning hub', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await _pump(
      tester,
      DawaLearnPage(
        repository: DawaLearningRepository(preferences: prefs),
      ),
    );
    await _capture(tester, 'learn.png');
  });

  testWidgets('capture care hub', (tester) async {
    await _pump(
      tester,
      DawaCarePage(
        initialAppointments: [_appointment()],
        initialClinics: const [
          ClinicOption(
            id: 'clinic-1',
            name: 'Kabulonga Clinic',
            address: 'Lusaka',
          ),
        ],
      ),
    );
    await _capture(tester, 'care.png');
  });

  testWidgets('capture myth and fact lesson', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await _pump(
      tester,
      DawaMythFactPage(
        repository: DawaLearningRepository(preferences: prefs),
      ),
    );
    await _capture(tester, 'myth-fact.png');
  });

  testWidgets('capture language sheet', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDawaLanguageSheet(
                context,
                initialValue: const DawaUserPreferences(),
              ),
              child: const Text('Open language'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open language'));
    await tester.pumpAndSettle();
    await _capture(tester, 'language-sheet.png');
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DawaTheme.light(),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final imageProviders = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(_captureKey));
    for (final provider in imageProviders) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) => expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile(
        '../docs/dawa_mom_screens/verification/$name',
      ),
    );

Appointment _appointment() => Appointment(
      id: 'appointment-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime.now().add(const Duration(days: 7)),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      status: 'confirmed',
      source: 'dawa_mom',
      createdAt: DateTime.now(),
      integrationStatus: 'synced',
      clinicianName: 'Dr Jane Banda',
      clinicianTitle: 'Midwife',
      clinicName: 'Kabulonga Clinic',
      clinicAddress: 'Lusaka',
    );
