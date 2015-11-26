@TestOn("vm")
import 'package:dev_test/test.dart';

import 'package:pubglobalupdate/global_package.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:cmdo/cmdo_io.dart';
import 'package:cmdo/dartbin.dart';
import 'dart:mirrors';
import 'package:path/path.dart';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;

main() {
  group('dummy_package', () {
    test('version_1', () async {
      CommandResult result = await io.runInput(pubCmd([
        'global',
        'activate',
        '-s',
        'path',
        join(dirname(testScriptPath), 'data', 'dummy_ver_1')
      ]));

      String packageName = 'tekartik_dummy_test';

      _findActivatedPackage() {
        GlobalPathPackage foundPackage;
        //print(result);
        for (String line in result.output.outLines) {
          GlobalPathPackage package =
              GlobalPackage.fromActivatedLine(line, packageName);
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, new Version(1, 0, 0));
        expect(foundPackage.source, endsWith(join('data', 'dummy_ver_1')));
      }
      _findActivatedPackage();

      String dartScript =
          join(dirname(dirname(testScriptPath)), 'bin', 'pubglobalupdate.dart');
      result = await io.run(dartVmBin, [dartScript, '-v', packageName]);
      _findActivatedPackage();
    });
  });
}
