@TestOn("vm")
import 'package:dev_test/test.dart';

import 'package:pubglobalupdate/src/global_package.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:mirrors';
import 'package:path/path.dart';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;

String get pubglobalupdateScript =>
    join(dirname(dirname(testScriptPath)), 'bin', 'pubglobalupdate.dart');

GlobalPackage fromUpdatedLine(String line, String packageName) {
  String updated = "updated: ";
  if (line.toLowerCase().startsWith(updated)) {
    int start = line.indexOf(packageName, updated.length);
    if (start != -1) {
      line = line.substring(0, line.length - 1);
    }
    GlobalPackage updatedPackage = GlobalPackage.fromListLine(line);
    return updatedPackage;
  }
  return null;
}

main() {
  group('activate_package', () {
    test('path', () async {
      ProcessResult result;
      String packageName = 'tekartik_pubglobalupdate_test_package';
      _findActivatedPackage() {
        GlobalPathPackage foundPackage;
        for (String line in LineSplitter.split(result.stdout)) {
          GlobalPathPackage package =
              GlobalPackage.fromActivatedLine(line, packageName);
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, new Version(1, 0, 0));
        expect(foundPackage.source, endsWith(join('data', 'test_package')));
      }
      result = await run(
          dartExecutable,
          pubArguments([
            'global',
            'activate',
            '-s',
            'path',
            join(dirname(testScriptPath), 'data', 'test_package'),
            '--overwrite'
          ]));
      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    });

    test('git', () async {
      ProcessResult result;
      String packageName = 'process_run';
      String source = 'https://github.com/tekartik/process_run.dart';
      _findActivatedPackage() {
        GlobalGitPackage foundPackage;
        //print(result);
        for (String line in LineSplitter.split(result.stdout)) {
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

      result = await run(
          dartExecutable,
          pubArguments(
              ['global', 'activate', '-s', 'git', source, '--overwrite']));

      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    });

    test('hosted', () async {
      ProcessResult result;
      String packageName = 'stagehand';
      _findActivatedPackage() {
        GlobalHostedPackage foundPackage;
        //print(result);
        for (String line in LineSplitter.split(result.stdout)) {
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

      result = await run(dartExecutable,
          pubArguments(['global', 'activate', '--overwrite', packageName]));

      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    });
  });
}
