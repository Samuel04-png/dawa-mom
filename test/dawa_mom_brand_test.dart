import 'package:dawa_mom/components/branding/dawa_mom_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brand variants use the DawaMom wordmark and cross',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            DawaMomLogo(variant: DawaMomLogoVariant.full),
            DawaMomLogo(variant: DawaMomLogoVariant.compact),
            DawaMomLogo(variant: DawaMomLogoVariant.authentication),
            DawaMomLogo(variant: DawaMomLogoVariant.wordmarkOnly),
          ],
        ),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((widget) => widget.image)
        .whereType<AssetImage>()
        .map((asset) => asset.assetName)
        .toSet();

    expect(assetNames, contains(DawaMomLogo.crossAsset));
    expect(assetNames, isNot(contains(DawaMomLogo.wordmarkAsset)));
    expect(assetNames, isNot(contains(DawaMomLogo.fullAsset)));
    expect(assetNames, isNot(contains('assets/images/app_logo_2.png')));
    expect(find.text('DawaMom'), findsWidgets);
  });
}
