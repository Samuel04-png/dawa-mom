import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every active contextual image chooses a named editorial variant', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => !file.path.endsWith('dawa_contextual_image.dart'),
        );

    for (final file in files) {
      final source = file.readAsStringSync();
      final imageCalls =
          RegExp(r'DawaContextualImage\s*\(').allMatches(source).length;
      if (imageCalls == 0) continue;
      final variantSelections =
          RegExp(r'variant:\s*DawaImageVariant\.').allMatches(source).length;
      expect(
        variantSelections,
        imageCalls,
        reason:
            '${file.path} has $imageCalls contextual image calls but $variantSelections named variants',
      );
    }
  });

  test('app image code never uses distortion-prone BoxFit.fill', () {
    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))) {
      if (file.readAsStringSync().contains('BoxFit.fill')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('image placement and variant audits are delivered', () {
    for (final path in const [
      'docs/dawamom_image_placement_audit.md',
      'docs/dawamom_image_variants.md',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.lengthSync(), greaterThan(1000), reason: path);
    }
  });
}
