@TestOn('vm')
library;

import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';

import 'package:test/test.dart';

String get testScriptDirPath => 'test';

String get pubglobalupdateScript =>
    join(dirname(testScriptDirPath), 'bin', 'pubglobalupdate.dart');

PubGlobalPackage? fromUpdatedLine(String line, String packageName) {
  const updated = 'updated: ';
  if (line.toLowerCase().startsWith(updated)) {
    final start = line.indexOf(packageName, updated.length);
    if (start != -1) {
      line = line.substring(0, line.length - 1);
    }
    final updatedPackage = PubGlobalPackage.fromListLine(line);
    return updatedPackage;
  }
  return null;
}

void main() {
  group('activate_package', () {
    test('path', () async {
      late List<ProcessResult> results;
      const packageName = 'tekartik_pubglobalupdate_test_package';
      void findActivatedPackage() {
        late PubGlobalPathPackage foundPackage;
        for (final line in results.outLines) {
          final package =
              PubGlobalPackage.fromActivatedLine(line, packageName)
                  as PubGlobalPathPackage?;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, Version(1, 0, 0));
        expect(foundPackage.source, endsWith(join('data', 'test_package')));
      }

      var cmd =
          'dart pub global activate -s path ${shellArgument(join(testScriptDirPath, 'data', 'test_package'))} --overwrite';
      results = await run(cmd);
      findActivatedPackage();

      results = await run(
        'dart run ${shellArgument(pubglobalupdateScript)} -v $packageName',
      );
      findActivatedPackage();
    });

    test('git', () async {
      late List<ProcessResult> results;
      const packageName = 'process_run';
      const source = 'https://github.com/tekartik/process_run.dart';
      void findActivatedPackage() {
        late PubGlobalGitPackage foundPackage;
        // print(result.stdout);
        for (final line in results.outLines) {
          final package =
              PubGlobalPackage.fromListLine(line) as PubGlobalGitPackage?;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, greaterThanOrEqualTo(Version(0, 1, 0)));
        expect(foundPackage.source, source);
      }

      await run(
        'dart pub global activate -s git ${shellArgument(source)} --overwrite',
      );
      results = await run('dart pub global list');
      findActivatedPackage();

      results = await run(
        'dart run ${shellArgument(pubglobalupdateScript)} -v $packageName',
      );
      findActivatedPackage();
    }, skip: 'process_run is no longer valid on dart1');

    test('hosted', () async {
      late List<ProcessResult> results;
      const packageName = 'dhttpd';
      void findActivatedPackage() {
        late PubGlobalHostedPackage foundPackage;
        //print(result);
        for (final line in results.outLines) {
          final package =
              PubGlobalPackage.fromActivatedLine(line, packageName)
                  as PubGlobalHostedPackage?;
          if (package != null) {
            foundPackage = package;
          }
        }
        expect(foundPackage.name, packageName);
        expect(foundPackage.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      }

      results = await run('dart pub global activate --overwrite $packageName');

      findActivatedPackage();

      results = await run(
        'dart run ${shellArgument(pubglobalupdateScript)} -v $packageName',
      );
      findActivatedPackage();
    });
  });
}
