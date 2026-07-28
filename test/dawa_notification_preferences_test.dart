import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/notifications/dawa_notification_preferences_page.dart';
import 'package:dawa_mom/features/notifications/dawa_notifications_page.dart';
import 'package:dawa_mom/features/preferences/dawa_user_preferences_repository.dart';
import 'package:dawa_mom/localization/dawa_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SharedPreferences preferences;
  late SupabaseClient offlineClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    offlineClient = SupabaseClient(
      'http://127.0.0.1:54321',
      'test-anon-key',
    );
  });

  tearDown(() async {
    await DawaLocaleController.instance.setLanguage(
      DawaLanguages.english,
      persist: false,
    );
  });

  test('notification preferences persist privacy and timing locally', () async {
    final repository = DawaUserPreferencesRepository(
      preferences: preferences,
      client: offlineClient,
    );
    final saved = await repository.save(
      const DawaUserPreferences().copyWith(
        weeklySummary: true,
        quietHoursStart: '22:30',
        quietHoursEnd: '06:15',
        privateLockScreen: true,
      ),
    );
    final restored = await repository.load();

    expect(saved.weeklySummary, isTrue);
    expect(restored.weeklySummary, isTrue);
    expect(restored.quietHoursStart, '22:30');
    expect(restored.quietHoursEnd, '06:15');
    expect(restored.privateLockScreen, isTrue);
  });

  test('mark all read preserves previously read notification IDs', () async {
    final repository = DawaNotificationsRepository(
      preferences: preferences,
      client: offlineClient,
      appointments: AppointmentRepository(client: offlineClient),
    );

    final read = await repository.markAllRead(
      {'older-notification'},
      {'current-notification'},
    );

    expect(read, {'older-notification', 'current-notification'});
    expect(
      preferences.getStringList('dawa_notification_read_ids')?.toSet(),
      {'older-notification', 'current-notification'},
    );
  });

  testWidgets('preferences page is usable at a narrow text-scaled viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final repository = DawaUserPreferencesRepository(
      preferences: preferences,
      client: offlineClient,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: DawaNotificationPreferencesPage(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification preferences'), findsOneWidget);
    expect(find.text('Private lock-screen wording'), findsOneWidget);
    expect(find.text('Weekly summary'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final weeklyTile = find.ancestor(
      of: find.text('Weekly summary'),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(weeklyTile);
    await tester.pumpAndSettle();
    await tester.tap(weeklyTile);
    await tester.pump();
    final save = find.byKey(
      const ValueKey('save-notification-preferences'),
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect((await repository.load()).weeklySummary, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preferences page fits every supported app language',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    for (var index = 1; index < DawaLanguages.locales.length; index++) {
      final locale = DawaLanguages.locales[index];
      await DawaLocaleController.instance.setLanguage(
        DawaLanguages.names[index],
        persist: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: DawaLanguages.locales,
          localizationsDelegates: const [
            DawaMaterialLocalizationsDelegate(),
            DawaCupertinoLocalizationsDelegate(),
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: ThemeData.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.2),
            ),
            child: DawaNotificationPreferencesPage(
              repository: DawaUserPreferencesRepository(
                preferences: preferences,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          DawaTranslations.translate('Notification preferences', locale),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
