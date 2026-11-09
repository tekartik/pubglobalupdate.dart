@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// A failing package does not stop the others (update and `--install`),
/// with `dart install` into a temporary DART_DATA_HOME and a temporary
/// config directory.
void main() {
  group('package errors', () {
    late Directory tempDir;
    late Shell shell;
    const script = 'bin/pubglobalupdate.dart';
    const gone = 'pgu_test_a_gone';
    const ok = 'pgu_test_b_ok';
    const missing = 'pgu_test_c_missing';

    /// A package with one executable, no dependency.
    Future<String> createPackage(String name) async {
      final dir = join(tempDir.path, 'packages', name);
      await Directory(join(dir, 'bin')).create(recursive: true);
      await File(join(dir, 'pubspec.yaml')).writeAsString(
        'name: $name\n'
        'environment:\n'
        '  sdk: ^3.12.0\n'
        'executables:\n'
        '  $name:\n',
      );
      await File(
        join(dir, 'bin', '$name.dart'),
      ).writeAsString("void main() => print('$name');\n");
      return dir;
    }

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('pubglobalupdate_test');
      shell = Shell(
        environment: {
          'DART_DATA_HOME': join(tempDir.path, 'dart_data_home'),
          'TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH': join(
            tempDir.path,
            'config',
          ),
        },
        verbose: false,
        throwOnError: false,
      );
    });
    tearDownAll(() async {
      for (final name in [gone, ok]) {
        await shell.run('dart uninstall $name');
      }
      await tempDir.delete(recursive: true);
    });

    test('update and install go on after a failure', () async {
      final gonePath = await createPackage(gone);
      final okPath = await createPackage(ok);
      // Installed last, listed first by `dart installed`.
      for (final (name, path) in [(ok, okPath), (gone, gonePath)]) {
        final result = (await shell.run(
          'dart install ${shellArgument('$name@{path: $path}')}',
        )).first;
        expect(result.exitCode, 0, reason: result.errText);
      }
      // The source of the first one is gone, its update fails.
      await Directory(gonePath).delete(recursive: true);

      var result = (await shell.run('dart run $script $gone $ok')).first;
      expect(
        result.exitCode,
        1,
        reason: '${result.outText}\n${result.errText}',
      );
      expect(result.outLines, contains('updating: $gone (install)'));
      expect(result.outLines, contains('updating: $ok (install)'));
      expect(result.outLines, contains(startsWith('updated: $ok ')));
      expect(result.errText, contains('error: $gone: '));
      expect(result.errLines.last, 'failed: $gone');

      // --install: a configured path that does not exist, then a good one.
      for (final (name, path) in [
        (missing, join(tempDir.path, 'none')),
        (ok, okPath),
      ]) {
        await shell.run(
          'dart run $script --config-package $name --source path '
          '--path ${shellArgument(path)} --tool install',
        );
      }
      result = (await shell.run(
        'dart run $script --install --tool install $missing $ok',
      )).first;
      expect(
        result.exitCode,
        1,
        reason: '${result.outText}\n${result.errText}',
      );
      expect(result.outLines, contains(startsWith('installed: $ok ')));
      expect(result.errLines.last, 'failed: $missing');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
