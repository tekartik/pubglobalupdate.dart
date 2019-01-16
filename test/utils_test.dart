import 'package:dev_test/test.dart';

import 'package:pubglobalupdate/src/utils.dart';

void main() {
  group('utils', () {
    test('insetString', () {
      expect(insetString("aba"), "b");
      expect(insetString("aa"), "");
      expect(insetString("a"), "a");
      expect(insetString(""), "");
    });

    test('extractSource', () {
      expect(extractSource("src"), "src");
      expect(extractSource("'src'"), "src");
      expect(extractSource('"src"'), "src");
      expect(extractSource('"\'src\'"'), "src");
      expect(extractSource('\'src\"'), '\'src"');
    });
  });
}
