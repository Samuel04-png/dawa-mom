import 'dart:async';

import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:dawa_mom/features/care_plan/data/dawa_care_plan_repository.dart';
import 'package:dawa_mom/features/care_plan/domain/dawa_care_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _mobileDestinations = <DawaMomShellDestination>[
  DawaMomShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  DawaMomShellDestination(
    label: 'Track',
    icon: Icons.sync_outlined,
    selectedIcon: Icons.sync,
  ),
  DawaMomShellDestination(
    label: 'Care',
    icon: Icons.health_and_safety_outlined,
    selectedIcon: Icons.health_and_safety,
  ),
  DawaMomShellDestination(
    label: 'Learn',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
  DawaMomShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

void main() {
  test('care repository identifies an undeployed care-plan table', () {
    expect(
      DawaCarePlanRepository.isMissingSchemaError(
        const PostgrestException(
          message:
              "Could not find the table 'public.care_plan_items' in the schema cache",
          code: 'PGRST205',
        ),
      ),
      isTrue,
    );
    expect(
      DawaCarePlanRepository.isMissingSchemaError(
        const PostgrestException(
          message: 'JWT expired',
          code: 'PGRST301',
        ),
      ),
      isFalse,
    );
  });

  testWidgets('Care defaults to Upcoming and renders real appointment data',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final appointment = _appointment();

    for (final size in const [
      Size(320, 568),
      Size(360, 800),
      Size(390, 844),
      Size(400, 793),
      Size(412, 915),
      Size(430, 932),
      Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      await _pumpCare(
        tester,
        DawaCarePage(
          initialAppointments: [appointment],
          initialClinics: const [
            ClinicOption(
              id: 'clinic-1',
              name: 'Kabulonga Clinic',
              address: 'Lusaka',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Your next visit'), findsOneWidget);
      expect(find.text('Dr Jane Banda'), findsOneWidget);
      expect(find.text('Kabulonga Clinic'), findsOneWidget);
      expect(find.text('Quick actions'), findsNothing);
      expect(find.text('Visit preparation: 3 of 5'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('care-tab-upcoming')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Upcoming visit keeps pending and confirmed states distinct',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: [
          _appointment(status: 'pending'),
        ],
        initialClinics: const [],
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsNothing);
    expect(find.text('View visit'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        DateFormat('EEEE, d MMMM y').format(
          DateTime.now().add(const Duration(days: 7)),
        ),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: [_appointment(status: 'confirmed')],
        initialClinics: const [],
      ),
    );
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care sections preserve the selected tab and show real content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final completed = _appointment(
      id: 'completed-1',
      status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 8)),
    );
    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: [_appointment(), completed],
        initialClinics: const [
          ClinicOption(
            id: 'clinic-1',
            name: 'Kabulonga Clinic',
            address: 'Lusaka',
            distanceKm: 2.4,
            isOpen: true,
            services: ['Antenatal care', 'General care'],
            isPreferred: true,
          ),
          ClinicOption(
            id: 'clinic-2',
            name: 'Chilenje Clinic',
            address: 'Chilenje',
            distanceKm: 4.8,
            services: ['Cervical screening'],
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const ValueKey('care-tab-clinics')));
    await tester.pumpAndSettle();
    expect(find.text('Find care near you'), findsOneWidget);
    expect(find.text('Nearest'), findsOneWidget);
    expect(find.text('Antenatal'), findsOneWidget);
    expect(find.text('Cervical'), findsOneWidget);
    expect(find.text('Preferred'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('care-tab-history')));
    await tester.pumpAndSettle();
    expect(find.text('Your previous care'), findsOneWidget);
    expect(find.text('View summary'), findsOneWidget);
    expect(find.textContaining('Dr Jane Banda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care empty Upcoming has one booking action and clinic browse',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await _pumpCare(
      tester,
      const DawaCarePage(
        initialAppointments: [],
        initialClinics: [
          ClinicOption(id: 'clinic-1', name: 'Kabulonga Clinic'),
        ],
      ),
    );

    expect(find.text('No visits yet'), findsOneWidget);
    expect(find.text('Book a visit'), findsOneWidget);
    expect(find.text('Find clinics'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    await tester.tap(find.text('Find clinics'));
    await tester.pumpAndSettle();
    expect(find.text('Find care near you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care maps a real server care item as the recommended next step',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final dueAt = DateTime.now().add(const Duration(days: 2));

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: const [],
        initialClinics: const [],
        initialCareItems: [
          DawaCareItem(
            id: 'care-1',
            motherId: 'mother-1',
            patientId: 'patient-1',
            type: 'screening_followup',
            title: 'Screening follow-up',
            status: DawaCareItemStatus.due,
            priority: DawaCareItemPriority.high,
            dueAt: dueAt,
            source: 'clinician',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      ),
    );

    expect(find.text('RECOMMENDED NEXT STEP'), findsOneWidget);
    expect(find.text('Screening follow-up'), findsOneWidget);
    expect(find.text('Due now'), findsOneWidget);
    expect(find.text('No visits yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care history includes completed non-appointment care items',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final completedAt = DateTime.now().subtract(const Duration(days: 1));

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: const [],
        initialClinics: const [],
        initialCareItems: [
          DawaCareItem(
            id: 'care-completed',
            motherId: 'mother-1',
            patientId: 'patient-1',
            type: 'learning',
            title: 'Nutrition lesson',
            status: DawaCareItemStatus.completed,
            priority: DawaCareItemPriority.routine,
            completedAt: completedAt,
            source: 'learning',
            createdAt: completedAt,
            updatedAt: completedAt,
          ),
        ],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('care-tab-history')));
    await tester.pumpAndSettle();

    expect(find.text('Other completed care'), findsOneWidget);
    expect(find.text('Nutrition lesson'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing care schema falls back without a patient warning',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: const [],
        initialClinics: const [],
        carePlanRepository: _CarePlanRepository(
          const DawaCarePlanSnapshot(
            items: [],
            isCached: false,
            availability: DawaCarePlanAvailability.schemaUnavailable,
          ),
        ),
      ),
    );

    expect(find.textContaining("couldn't refresh"), findsNothing);
    expect(find.textContaining('unavailable'), findsNothing);
    expect(find.text('No visits yet'), findsOneWidget);
  });

  testWidgets('cached care remains visible when live refresh is unavailable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final now = DateTime.now();

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: const [],
        initialClinics: const [],
        carePlanRepository: _CarePlanRepository(
          DawaCarePlanSnapshot(
            items: [
              DawaCareItem(
                id: 'cached-care',
                motherId: 'mother-1',
                patientId: 'patient-1',
                type: 'clinical_followup',
                title: 'Saved follow-up',
                status: DawaCareItemStatus.due,
                priority: DawaCareItemPriority.high,
                source: 'clinician',
                createdAt: now,
                updatedAt: now,
              ),
            ],
            isCached: true,
            cachedAt: now,
            availability: DawaCarePlanAvailability.cached,
          ),
        ),
      ),
    );

    expect(find.text('Saved follow-up'), findsOneWidget);
    expect(
        find.textContaining('Showing saved care information'), findsOneWidget);
    expect(find.textContaining("couldn't refresh"), findsNothing);
  });

  testWidgets('temporary care failure uses a compact section retry state',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final repository = _PendingCarePlanRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: DawaCarePage(
          initialAppointments: const [],
          initialClinics: const [],
          carePlanRepository: repository,
        ),
      ),
    );
    await tester.pump();
    repository.fail();
    await tester.pumpAndSettle();

    expect(find.text("Care recommendations couldn't refresh"), findsOneWidget);
    expect(find.text('Your appointments are still available.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Recommended care unavailable'), findsNothing);
  });

  testWidgets('clinic card hides missing metadata and stays compact',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    await _pumpCare(
      tester,
      const DawaCarePage(
        initialAppointments: [],
        initialClinics: [
          ClinicOption(id: 'clinic-minimal', name: 'Kabulonga Clinic'),
        ],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('care-tab-clinics')));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('clinic-card-clinic-minimal'));
    expect(card, findsOneWidget);
    expect(tester.getSize(card).height, lessThan(190));
    expect(find.textContaining('Unknown'), findsNothing);
    expect(find.textContaining('N/A'), findsNothing);
    expect(find.textContaining('No services'), findsNothing);
    expect(find.text('View clinic'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clinic actions clear floating navigation at 320px',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: DawaMomResponsiveShell(
          currentIndex: 2,
          destinations: _mobileDestinations,
          onDestinationSelected: (_) {},
          onLogout: () async {},
          child: const DawaCarePage(
            initialAppointments: [],
            initialClinics: [
              ClinicOption(
                id: 'clinic-actions',
                name: 'Kabulonga Clinic',
                address: 'Lusaka',
                services: ['Antenatal care'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('care-tab-clinics')));
    await tester.pumpAndSettle();

    final book = find.text('Book');
    await tester.ensureVisible(book);
    await tester.pumpAndSettle();

    final bookRect = tester.getRect(book);
    final navRect = tester.getRect(find.byType(BottomNavigationBar));
    final rudoRect =
        tester.getRect(find.byKey(const ValueKey('rudo-launcher')));
    expect(bookRect.bottom, lessThan(navRect.top));
    expect(bookRect.overlaps(rudoRect), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history keeps one clear status and a compact primary action',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: [
          _appointment(
            id: 'cancelled-history',
            status: 'cancelled',
            date: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ],
        initialClinics: const [],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('care-tab-history')));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('care-history-cancelled-history'));
    expect(card, findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(tester.getSize(card).height, lessThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care cancellation waits for repository confirmation',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = _ControlledAppointmentRepository();
    await _pumpCare(
      tester,
      DawaCarePage(
        repository: repository,
        initialAppointments: [_appointment()],
        initialClinics: const [],
      ),
    );

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel appointment'));
    await tester.pump();
    expect(find.text('Please wait'), findsOneWidget);
    expect(find.text('Your next visit'), findsOneWidget);

    repository.completeCancellation();
    await tester.pumpAndSettle();
    expect(find.text('No visits yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCare(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DawaTheme.light(),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Appointment _appointment({
  String id = 'appointment-1',
  String status = 'confirmed',
  DateTime? date,
}) =>
    Appointment(
      id: id,
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: date ?? DateTime.now().add(const Duration(days: 7)),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      status: status,
      source: 'dawa_mom',
      createdAt: DateTime.now(),
      integrationStatus: 'synced',
      clinicianName: 'Dr Jane Banda',
      clinicName: 'Kabulonga Clinic',
      clinicAddress: 'Lusaka',
    );

class _ControlledAppointmentRepository extends AppointmentRepository {
  _ControlledAppointmentRepository()
      : super(
          client: SupabaseClient(
            'http://127.0.0.1:54321',
            'care-test-anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final _cancellation = Completer<Appointment>();

  @override
  Future<Appointment> cancelAppointment(String id) => _cancellation.future;

  void completeCancellation() {
    _cancellation.complete(
      _appointment(
        id: 'appointment-1',
        status: 'cancelled',
        date: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }
}

class _CarePlanRepository extends DawaCarePlanRepository {
  _CarePlanRepository(this.snapshot);

  final DawaCarePlanSnapshot snapshot;

  @override
  Future<DawaCarePlanSnapshot> load() async => snapshot;
}

class _PendingCarePlanRepository extends DawaCarePlanRepository {
  final _result = Completer<DawaCarePlanSnapshot>();

  @override
  Future<DawaCarePlanSnapshot> load() => _result.future;

  void fail() => _result.completeError(Exception('offline'));
}
