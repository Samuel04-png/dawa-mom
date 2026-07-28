import 'package:dawa_mom/design_system/dawa_contextual_image.dart';
import 'package:dawa_mom/content/dawa_learning_asset_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('missing'));
}

void main() {
  testWidgets('keeps stable geometry and exposes localized image semantics',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'ZM'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DawaContextualImage(
              assetId: 'pregnancy_basics_01',
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(ratio.aspectRatio, 16 / 9);
    expect(
      find.bySemanticsLabel('Educational image about pregnancy wellbeing'),
      findsOneWidget,
    );
  });

  testWidgets('renders an intentional fallback when an asset cannot load',
      (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _FailingBundle(),
        child: const MaterialApp(
          home: Scaffold(
            body: DawaContextualImage(
              assetId: 'cervical_awareness_01',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.byKey(
        const ValueKey(
          'dawa-contextual-image-fallback-cervical_awareness_01',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion disables Hero animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DawaContextualImage(
            assetId: 'period_tracking_01',
            heroTag: 'period-cover',
          ),
        ),
      ),
    );
    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('named variants own geometry, fit and focal alignment',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DawaContextualImage(
              assetId: 'period_tracking_01',
              variant: DawaImageVariant.journeyHero,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    final image = tester.widget<Image>(
      find.byKey(
        const ValueKey('dawa-contextual-image-period_tracking_01'),
      ),
    );
    expect(ratio.aspectRatio, 4 / 3);
    expect(image.fit, BoxFit.cover);
    expect(
      image.alignment,
      DawaLearningAssetRegistry.byId('period_tracking_01')
          .alignmentFor(DawaImageVariant.journeyHero),
    );
    expect(
      find.byKey(
        const ValueKey(
          'dawa-contextual-frame-period_tracking_01-journeyHero',
        ),
      ),
      findsOneWidget,
    );
  });

  test('no editorial variant distorts an image', () {
    for (final variant in DawaImageVariant.values) {
      expect(variant.layout.fit, isNot(BoxFit.fill), reason: variant.name);
      expect(variant.layout.aspectRatio, greaterThan(0), reason: variant.name);
      expect(variant.layout.maximumHeight, greaterThan(0),
          reason: variant.name);
    }
  });
}
