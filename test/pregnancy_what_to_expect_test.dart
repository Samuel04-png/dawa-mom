import 'package:dawa_mom/features/pregnancy/presentation/pregnancy_what_to_expect.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HealthProfileSnapshot _profile({
  required String status,
  Map<String, dynamic>? pregnancy,
}) {
  return HealthProfileSnapshot(
    profile: const {'email': 'patient@example.com'},
    mother: {'pregnancy_status': status},
    pregnancy: pregnancy,
    periodSettings: null,
  );
}

Widget _card(HealthProfileSnapshot profile) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 720,
          child: PregnancyWhatToExpectCard(
            profile: profile,
            onOpenProfile: () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('pregnant profile uses the shared pregnancy overview',
      (tester) async {
    await tester.pumpWidget(_card(_profile(
      status: 'pregnant',
      pregnancy: const {'estimated_due_date': '2026-11-20'},
    )));

    expect(find.text('Pregnancy overview'), findsOneWidget);
    expect(find.textContaining('Estimated due date'), findsOneWidget);
    expect(find.text('No pregnancy data'), findsNothing);
  });

  testWidgets('missing pregnancy dates have an actionable state',
      (tester) async {
    await tester.pumpWidget(_card(_profile(status: 'pregnant')));

    expect(find.text('Pregnancy details need completion'), findsOneWidget);
    expect(find.text('Complete pregnancy details'), findsOneWidget);
  });

  testWidgets('not pregnant is explicit instead of shown as missing data',
      (tester) async {
    await tester.pumpWidget(_card(_profile(status: 'not_pregnant')));

    expect(find.text('Pregnancy tips are off'), findsOneWidget);
    expect(find.text('No pregnancy data'), findsNothing);
  });

  testWidgets('not provided remains distinct from not pregnant',
      (tester) async {
    await tester.pumpWidget(_card(_profile(status: 'not_provided')));

    expect(find.text('Pregnancy status not provided'), findsOneWidget);
  });
}
