@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// Config files against a temporary user app data path (never the real one).
void main() {
  group('config io', () {
    late Directory tempDir;
    late Shell shell;
    late String configDir;
    const script = 'bin/pubglobalupdate.dart';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pubglobalupdate_config');
      var appDataPath = join(tempDir.path, 'app_data');
      configDir = join(appDataPath, 'tekartik', 'pubglobalupdate', 'config');
      shell = Shell(
        environment: {'TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH': appDataPath},
        verbose: false,
      );
    });
    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('no config saved yet', () async {
      expect(Directory(configDir).existsSync(), isFalse);
      var result = (await shell.run('dart run $script --package-list')).first;
      expect(result.outText.trim(), isEmpty);
      result = (await shell.run('dart run $script --config-list')).first;
      expect(result.outText, startsWith('settings: '));
    });

    test('yaml, json and unreadable configs', () async {
      await Directory(configDir).create(recursive: true);
      await File(
        join(configDir, 'hand.yaml'),
      ).writeAsString('package: hand\nsource: hosted\nversion: ^1.0.0\n');
      await File(join(configDir, 'saved.yaml')).writeAsString(
        jsonEncode({'package': 'saved', 'source': 'path', 'path': 'p'}),
      );
      await File(join(configDir, 'bad.yaml')).writeAsString('{bad');

      var result = (await shell.run('dart run $script --config-list')).first;
      var out = result.outText;
      expect(out, contains('"package": "hand"'));
      expect(out, contains('"version": "^1.0.0"'));
      expect(out, contains('"package": "saved"'));
      expect(out, contains('bad:'));
      expect(result.errText, contains('Error reading config for bad'));

      result = (await shell.run(
        'dart run $script --config-package hand --config-read',
      )).first;
      expect(result.outText, contains('"source": "hosted"'));
    });
  });
}
