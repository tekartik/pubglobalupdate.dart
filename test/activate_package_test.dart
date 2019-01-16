@TestOn("vm")
library pubglobalupdate.test.activate_package_test;

import 'dart:convert';
import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/process_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/global_package.dart';

String get testScriptDirPath => 'test';

String get pubglobalupdateScript =>
    join(dirname(testScriptDirPath), 'bin', 'pubglobalupdate.dart');

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

void main() {
  group('activate_package', () {
    test('path', () async {
      ProcessResult result;
      String packageName = 'tekartik_pubglobalupdate_test_package';
      void _findActivatedPackage() {
        GlobalPathPackage foundPackage;
        for (String line in LineSplitter.split(result.stdout.toString())) {
          GlobalPathPackage package =
              GlobalPackage.fromActivatedLine(line, packageName)
                  as GlobalPathPackage;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, Version(1, 0, 0));
        expect(foundPackage.source, endsWith(join('data', 'test_package')));
      }

      var cmd = PubCmd([
        'global',
        'activate',
        '-s',
        'path',
        join(testScriptDirPath, 'data', 'test_package'),
        '--overwrite'
      ]);
      result = await runCmd(cmd);
      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    });

    test('git', () async {
      ProcessResult result;
      String packageName = 'process_run';
      String source = 'https://github.com/tekartik/process_run.dart';
      void _findActivatedPackage() {
        GlobalGitPackage foundPackage;
        // print(result.stdout);
        for (String line in LineSplitter.split(result.stdout.toString())) {
          GlobalGitPackage package =
              GlobalPackage.fromListLine(line) as GlobalGitPackage;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, greaterThanOrEqualTo(Version(0, 1, 0)));
        expect(foundPackage.source, source);
      }

      result = await runCmd(
          PubCmd(['global', 'activate', '-s', 'git', source, '--overwrite']));
      result = await runCmd(PubCmd(['global', 'list']));
      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    }, skip: 'process_run is no longer valid on dart1');

    test('hosted', () async {
      ProcessResult result;
      String packageName = 'stagehand';
      void _findActivatedPackage() {
        GlobalHostedPackage foundPackage;
        //print(result);
        for (String line in LineSplitter.split(result.stdout.toString())) {
          GlobalHostedPackage package =
              GlobalPackage.fromActivatedLine(line, packageName)
                  as GlobalHostedPackage;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      }

      result = await runCmd(
          PubCmd(['global', 'activate', '--overwrite', packageName]));

      _findActivatedPackage();

      result =
          await run(dartExecutable, [pubglobalupdateScript, '-v', packageName]);
      _findActivatedPackage();
    });
  });
}
