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
  group('activate_package', () {
    test('path', () async {
      CommandResult result = await io.runCmd(pubCmd([
        'global',
        'activate',
        '-s',
        'path',
        join(dirname(testScriptPath), 'data', 'dummy_ver_1'),
        '--overwrite'
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
      result = await io.runCmd(dartBinCmd([dartScript, '-v', packageName]));
      _findActivatedPackage();
    });

    test('git', () async {
      String packageName = 'cmdo';
      String source = 'https://github.com/tekartik/cmdo.dart';

      CommandResult result = await io.runCmd(
          pubCmd(['global', 'activate', '-s', 'git', source, '--overwrite']));

      _findActivatedPackage() {
        GlobalGitPackage foundPackage;
        //print(result);
        for (String line in result.output.outLines) {
          GlobalGitPackage package =
              GlobalPackage.fromActivatedLine(line, packageName);
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(
            foundPackage.version, greaterThanOrEqualTo(new Version(0, 1, 0)));
        expect(foundPackage.source, source);
      }
      _findActivatedPackage();

      String dartScript =
          join(dirname(dirname(testScriptPath)), 'bin', 'pubglobalupdate.dart');
      result = await io.runCmd(dartBinCmd([dartScript, '-v', packageName]));
      _findActivatedPackage();
    });

    test('hosted', () async {
      String packageName = 'stagehand';

      CommandResult result = await io
          .runCmd(pubCmd(['global', 'activate', '--overwrite', packageName]));

      _findActivatedPackage() {
        GlobalHostedPackage foundPackage;
        //print(result);
        for (String line in result.output.outLines) {
          GlobalHostedPackage package =
              GlobalPackage.fromActivatedLine(line, packageName);
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(
            foundPackage.version, greaterThanOrEqualTo(new Version(0, 1, 0)));
      }
      _findActivatedPackage();

      String dartScript =
          join(dirname(dirname(testScriptPath)), 'bin', 'pubglobalupdate.dart');
      result = await io.runCmd(dartBinCmd([dartScript, '-v', packageName]));
      _findActivatedPackage();
    });
  });
}
