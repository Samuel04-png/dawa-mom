import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/profile/profile_completion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _client = SupabaseClient(
  'http://localhost:54321',
  'local-anon-key-for-widget-tests',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  testWidgets(
    'pregnancy step explains the personal-details prerequisite before save',
    (tester) async {
      final repository = _PregnancyProfileRepository(hasMaternalProfile: false);
      await tester.pumpWidget(_page(repository));
      await tester.pumpAndSettle();

      final pregnancyStep = find.text('Pregnancy choice');
      await tester.ensureVisible(pregnancyStep);
      await tester.tap(pregnancyStep);
      await tester.pumpAndSettle();

      expect(find.text('Add your details first'), findsOneWidget);
      expect(repository.pregnancySaveCalls, 0);
      expect(find.text('Pregnancy information'), findsNothing);
    },
  );

  testWidgets(
    'pregnancy confirmation appears only after the repository save completes',
    (tester) async {
      final repository = _PregnancyProfileRepository(hasMaternalProfile: true);
      await tester.pumpWidget(_page(repository));
      await tester.pumpAndSettle();

      final pregnancyStep = find.text('Pregnancy choice');
      await tester.ensureVisible(pregnancyStep);
      await tester.tap(pregnancyStep);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.pregnancySaveCalls, 1);
      expect(find.text('Pregnancy choice saved'), findsOneWidget);
    },
  );
}

Widget _page(HealthProfileRepository repository) => MaterialApp(
      home: ProfileCompletionPage(repository: repository),
    );

class _PregnancyProfileRepository extends HealthProfileRepository {
  _PregnancyProfileRepository({required this.hasMaternalProfile})
      : super(client: _client);

  final bool hasMaternalProfile;
  int pregnancySaveCalls = 0;
  String _pregnancyStatus = 'not_provided';

  @override
  Future<HealthProfileSnapshot> load() async => HealthProfileSnapshot(
        profile: const {
          'email': 'test@example.test',
          'display_name': 'Test Mom',
          'phone_number': '+260970000000',
        },
        mother: {
          if (hasMaternalProfile) 'id': 'a640689d-6bb9-48f2-8ed8-f76e91310d5e',
          'name': 'Test Mom',
          'phone_number': '+260970000000',
          'date_of_birth': '1995-01-01',
          'address': 'Lusaka',
          'pregnancy_status': _pregnancyStatus,
        },
        pregnancy: null,
        periodSettings: const {'lastPeriodStart': null},
      );

  @override
  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {
    await Future<void>.delayed(Duration.zero);
    pregnancySaveCalls++;
    _pregnancyStatus = status;
  }
}
