import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web metadata uses Dawa Mom title and generated compact icons', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

    expect(index, contains('<title>Dawa Mom</title>'));
    expect(index, contains('href="favicon.png"'));
    expect(index, isNot(contains('Group_1_dark.png')));
    expect(manifest['name'], 'Dawa Mom');
    expect(manifest['short_name'], 'Dawa Mom');
    expect(File('web/favicon.png').lengthSync(), greaterThan(0));
    expect(File('web/icons/Icon-192.png').lengthSync(), greaterThan(0));
    expect(File('web/icons/Icon-512.png').lengthSync(), greaterThan(0));
  });
}
