@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// dart install support, against a temporary DART_DATA_HOME and a temporary
/// config directory. The pub global side uses the real pub cache like the
/// other io tests (a temporary PUB_CACHE would make `dart run` re-resolve the
/// workspace into it).
void main() {
  group('install', () {
    late Directory tempDir;
    late Shell shell;
    late String dataHome;
    final tkhelloPath = normalize(
      absolute(join('..', '..', 'example', 'packages', 'tkhello')),
    );
    const script = 'bin/pubglobalupdate.dart';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('pubglobalupdate_test');
      dataHome = join(tempDir.path, 'dart_data_home');
      shell = Shell(
        environment: {
          'DART_DATA_HOME': dataHome,
          'TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH': join(
            tempDir.path,
            'config',
          ),
        },
        verbose: false,
      );
    });
    tearDownAll(() async {
      try {
        await shell.run('dart uninstall tkhello');
      } catch (_) {}
      try {
        await shell.run('dart pub global deactivate tkhello');
      } catch (_) {}
      await tempDir.delete(recursive: true);
    });

    test('config, install, list, update, migrate', () async {
      // Save the config with the tool.
      await shell.run(
        'dart run $script --config-package tkhello --source path '
        '--path ${shellArgument(tkhelloPath)} --tool install',
      );
      var lines = (await shell.run(
        'dart run $script --config-package tkhello --config-read',
      )).outLines;
      expect(lines.join('\n'), contains('"tool": "install"'));

      // Dry run shows the dart install command.
      lines = (await shell.run(
        'dart run $script --install --dry-run tkhello',
      )).outLines;
      expect(
        lines.last,
        'dart install "tkhello@{path: $tkhelloPath}" --overwrite',
      );

      // Install for real, into the temporary DART_DATA_HOME.
      lines = (await shell.run('dart run $script --install tkhello')).outLines;
      expect(lines.first, 'installing: tkhello (install)');
      expect(lines.last, startsWith('installed: tkhello '));
      expect(
        File(join(dataHome, 'install', 'bin', 'tkhello')).existsSync(),
        isTrue,
      );

      // Listed with its tool.
      lines = (await shell.run('dart run $script --list')).outLines;
      expect(
        lines.where((line) => line.startsWith('tkhello ')).single,
        'tkhello 1.0.0 (install, path $tkhelloPath)',
      );

      // Update runs dart install again.
      lines = (await shell.run('dart run $script --dry-run tkhello')).outLines;
      expect(lines, [
        'dart install "tkhello@{path: $tkhelloPath}" --overwrite',
      ]);
      lines = (await shell.run('dart run $script tkhello')).outLines;
      expect(lines.first, 'updating: tkhello (install)');
      expect(lines.last, startsWith('updated: tkhello '));

      // Migrate to pub global activate (real pub cache), config updated.
      lines = (await shell.run(
        'dart run $script --migrate --tool activate tkhello',
      )).outLines;
      expect(lines.first, 'removing: tkhello (install)');
      expect(lines, contains('config: tkhello tool activate'));
      expect(
        File(join(dataHome, 'install', 'bin', 'tkhello')).existsSync(),
        isFalse,
      );
      lines = (await shell.run('dart run $script --list')).outLines;
      expect(
        lines.where((line) => line.startsWith('tkhello ')).single,
        'tkhello 1.0.0 (activate, path $tkhelloPath)',
      );
      lines = (await shell.run(
        'dart run $script --config-package tkhello --config-read',
      )).outLines;
      expect(lines.join('\n'), contains('"tool": "activate"'));

      // A config asking for install while activated: hint, no move.
      await shell.run(
        'dart run $script --config-package tkhello --source path '
        '--path ${shellArgument(tkhelloPath)} --tool install',
      );
      lines = (await shell.run('dart run $script --dry-run tkhello')).outLines;
      expect(lines.first, startsWith('hint: tkhello is installed with'));
      expect(lines.last, startsWith('dart pub global activate '));

      // Doctor runs.
      lines = (await shell.run('dart run $script --doctor')).outLines;
      expect(lines.first, startsWith('default tool: '));
      expect(lines.join('\n'), contains('pub global bin: '));
      expect(lines.join('\n'), contains('dart install bin: $dataHome'));

      // Default tool setting.
      await shell.run('dart run $script --default-tool install');
      lines = (await shell.run('dart run $script --config-list')).outLines;
      expect(lines.first, startsWith('settings: '));
      expect(lines.join('\n'), contains('"default-tool": "install"'));
      await shell.run(
        'dart run $script --config-package tkhello --config-clear',
      );
      lines = (await shell.run(
        'dart run $script --install --dry-run tkhello',
      )).outLines;
      expect(lines.last, 'dart install tkhello --overwrite');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
