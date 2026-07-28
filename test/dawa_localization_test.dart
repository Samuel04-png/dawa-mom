import 'dart:io';

import 'package:dawa_mom/features/preferences/dawa_language_sheet.dart';
import 'package:dawa_mom/features/preferences/dawa_user_preferences_repository.dart';
import 'package:dawa_mom/localization/dawa_localized_material.dart' as dawa;
import 'package:flutter/material.dart' as material;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await dawa.DawaLocaleController.instance.setLanguage(
      dawa.DawaLanguages.english,
      persist: false,
    );
  });

  tearDown(() async {
    await dawa.DawaLocaleController.instance.setLanguage(
      dawa.DawaLanguages.english,
      persist: false,
    );
  });

  test('all five language choices map to stable Zambian locales', () {
    expect(dawa.DawaLanguages.names, hasLength(5));
    expect(
      dawa.DawaLanguages.locales.map((locale) => locale.languageCode),
      ['en', 'ny', 'bem', 'toi', 'loz'],
    );
    for (var index = 0; index < dawa.DawaLanguages.names.length; index++) {
      expect(
        dawa.DawaLanguages.nameForLocale(dawa.DawaLanguages.locales[index]),
        dawa.DawaLanguages.names[index],
      );
    }
  });

  test('language choice persists and updates the active locale', () async {
    await dawa.DawaLocaleController.instance.setLanguage(
      dawa.DawaLanguages.bemba,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(dawa.DawaLocaleController.preferenceKey),
      dawa.DawaLanguages.bemba,
    );
    expect(
      dawa.DawaLocaleController.instance.locale,
      const material.Locale('bem', 'ZM'),
    );
  });

  test('legacy unsupported language preferences safely normalize to English',
      () async {
    SharedPreferences.setMockInitialValues({
      dawa.DawaLocaleController.preferenceKey: 'Shona',
    });
    final preferences = await SharedPreferences.getInstance();
    final value = await DawaUserPreferencesRepository(
      preferences: preferences,
    ).load();

    expect(value.language, dawa.DawaLanguages.english);
    expect(
      dawa.DawaLocaleController.instance.locale,
      const material.Locale('en', 'ZM'),
    );
  });

  test('catalog translates navigation, health, dates, and brand safely', () {
    for (final locale in dawa.DawaLanguages.locales.skip(1)) {
      expect(
        dawa.DawaTranslations.translate('Home', locale),
        isNot('Home'),
      );
      expect(
        dawa.DawaTranslations.translate('Choose language', locale),
        isNot('Choose language'),
      );
      expect(
        dawa.DawaTranslations.translate('Urgent care', locale),
        isNot('Urgent care'),
      );
      expect(
        dawa.DawaTranslations.translate('Monday, 20 July 2026', locale),
        isNot(contains('Monday')),
      );
      expect(
        dawa.DawaTranslations.translate('Dawa Mom', locale),
        'DawaMom',
      );
    }

    expect(
      dawa.DawaTranslations.translate(
        'Monday and birthday',
        const material.Locale('ny', 'ZM'),
      ),
      'Lolemba and birthday',
    );
  });

  test('new Home, Learn, Profile, and onboarding copy translates', () {
    const patientCopy = [
      'For today',
      'What do you need?',
      'Your pregnancy',
      'Your cycle today',
      'Your health today',
      'Finish your health profile',
      'Next step: add your name and date of birth.',
      'Today’s pick',
      'The Mother’s Path',
      'Your guide and friend',
      'Small lessons. Clear answers.',
      'Search health lessons',
      'Picked for you',
      'Tell us a little about you',
      'Your four steps',
      'How to reach you',
      'Pregnancy choice',
      'Your period dates',
      'To do',
      'Book a visit with ease',
      'Health answers you can trust',
      'Know your cycle',
      'Learn, play and earn',
    ];
    for (final locale in dawa.DawaLanguages.locales.skip(1)) {
      for (final source in patientCopy) {
        expect(
          dawa.DawaTranslations.translate(source, locale),
          isNot(source),
          reason: '$source did not translate for ${locale.languageCode}',
        );
      }
    }
  });

  test('built-in Material controls use the active language', () async {
    for (final locale in dawa.DawaLanguages.locales.skip(1)) {
      final localizations =
          await const dawa.DawaMaterialLocalizationsDelegate().load(locale);
      expect(
        localizations.cancelButtonLabel,
        dawa.DawaTranslations.translate('Cancel', locale),
      );
      expect(
        localizations.formatMonthYear(DateTime(2026, 7)),
        contains(dawa.DawaTranslations.translate('July', locale)),
      );
      expect(localizations.dateHelpText, 'dd/mm/yyyy');
    }
  });

  testWidgets(
    'visible text, form labels, and accessibility copy rebuild per language',
    (tester) async {
      for (var index = 1; index < dawa.DawaLanguages.locales.length; index++) {
        final locale = dawa.DawaLanguages.locales[index];
        await dawa.DawaLocaleController.instance.setLanguage(
          dawa.DawaLanguages.names[index],
          persist: false,
        );
        final translatedHome = dawa.DawaTranslations.translate('Home', locale);
        final translatedLanguage =
            dawa.DawaTranslations.translate('Language', locale);
        final translatedChoice =
            dawa.DawaTranslations.translate('Choose language', locale);

        await tester.pumpWidget(
          material.MaterialApp(
            locale: locale,
            supportedLocales: dawa.DawaLanguages.locales,
            localizationsDelegates: const [
              dawa.DawaMaterialLocalizationsDelegate(),
              dawa.DawaCupertinoLocalizationsDelegate(),
              GlobalWidgetsLocalizations.delegate,
            ],
            home: material.Scaffold(
              body: material.Column(
                children: [
                  const dawa.Text('Home'),
                  material.TextField(
                    decoration: dawa.InputDecoration(
                      labelText: 'Language',
                    ),
                  ),
                  dawa.Semantics(
                    key: const material.ValueKey('language-semantics'),
                    label: 'Choose language',
                    child: const material.SizedBox(width: 44, height: 44),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(translatedHome), findsOneWidget);
        expect(find.text(translatedLanguage), findsOneWidget);
        expect(
          tester.getSemantics(
            find.byKey(const material.ValueKey('language-semantics')),
          ),
          matchesSemantics(label: translatedChoice),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('language sheet previews a choice and restores on cancel',
      (tester) async {
    await tester.pumpWidget(_languageHarness());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const material.ValueKey('open-language-sheet')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bemba'));
    await tester.pumpAndSettle();

    expect(
      dawa.DawaLocaleController.instance.locale,
      const material.Locale('bem', 'ZM'),
    );
    expect(find.text('Saleni ululimi'), findsWidgets);

    await tester.tap(
      find.text(
        dawa.DawaTranslations.translate(
          'Cancel',
          const material.Locale('bem', 'ZM'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      dawa.DawaLocaleController.instance.locale,
      const material.Locale('en', 'ZM'),
    );
  });

  test('runtime product copy always spells DawaMom as one word', () {
    const roots = [
      'lib',
      'web',
      'android/app/src/main',
      'ios/Runner',
      'supabase/functions',
    ];
    final violations = <String>[];
    for (final root in roots) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File ||
            entity.path.endsWith('dawa_localizations.dart')) {
          continue;
        }
        final extension = entity.path.split('.').last.toLowerCase();
        if (!{
          'dart',
          'html',
          'json',
          'xml',
          'plist',
          'ts',
          'md',
        }.contains(extension)) {
          continue;
        }
        if (entity.readAsStringSync().contains('Dawa Mom')) {
          violations.add(entity.path);
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('patient-facing Dart copy does not use em dashes', () {
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          entity.readAsStringSync().contains('—')) {
        violations.add(entity.path);
      }
    }
    expect(violations, isEmpty);
  });
}

material.Widget _languageHarness() {
  final controller = dawa.DawaLocaleController.instance;
  return material.AnimatedBuilder(
    animation: controller,
    builder: (context, _) => material.MaterialApp(
      locale: controller.locale,
      supportedLocales: dawa.DawaLanguages.locales,
      localizationsDelegates: const [
        dawa.DawaMaterialLocalizationsDelegate(),
        dawa.DawaCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
      home: material.Scaffold(
        body: material.Builder(
          builder: (context) => material.Center(
            child: material.FilledButton(
              key: const material.ValueKey('open-language-sheet'),
              onPressed: () => showDawaLanguageSheet(
                context,
                initialValue: const DawaUserPreferences(),
              ),
              child: const dawa.Text('Choose language'),
            ),
          ),
        ),
      ),
    ),
  );
}
