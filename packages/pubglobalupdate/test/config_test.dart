import 'package:pubglobalupdate/src/config.dart';
import 'package:pubglobalupdate/src/tool.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('config', () {
    test('git', () {
      var config = PubGlobalPackageConfig(
        package: 'test_package',
        source: 'git',
        gitUrl: 'http://test',
        gitRef: 'main',
        gitPath: 'test',
      );
      expect(config.toMap(), {
        'package': 'test_package',
        'source': 'git',
        'git-path': 'test',
        'git-ref': 'main',
        'git-url': 'http://test',
      });
      expect(
        config.toActivateArgsString(),
        '--source git http://test --git-path test --git-ref main',
      );
    });
    test('path', () {
      var config = PubGlobalPackageConfig(
        package: 'test_package',
        source: 'path',
        path: 'my_path',
      );
      expect(config.toMap(), {
        'package': 'test_package',
        'source': 'path',
        'path': 'my_path',
      });
      expect(config.toActivateArgsString(), '--source path my_path');
    });
    test('hosted', () {
      var config = PubGlobalPackageConfig(
        package: 'test_package',
        source: 'hosted',
      );
      expect(config.toMap(), {'package': 'test_package', 'source': 'hosted'});
      expect(config.toActivateArgsString(), 'test_package');
    });
    test('default', () {
      var config = PubGlobalPackageConfig(package: 'test_package');
      expect(config.toMap(), {'package': 'test_package'});
      expect(config.toActivateArgsString(), 'test_package');
    });
    test('install args', () {
      expect(
        PubGlobalPackageConfig(
          package: 'p',
          source: 'git',
          gitUrl: 'http://test',
          gitRef: 'main',
          gitPath: 'packages/p',
        ).toInstallArgsString(),
        '"p@{git: {url: http://test, ref: main, path: packages/p}}"',
      );
      expect(
        PubGlobalPackageConfig(
          package: 'p',
          source: 'path',
          path: '/my path',
        ).toInstallArgsString(),
        '"p@{path: /my path}"',
      );
      expect(PubGlobalPackageConfig(package: 'p').toInstallArgsString(), 'p');
      expect(
        PubGlobalPackageConfig(package: 'p', version: '^1.3.0').installArgs,
        ['p@^1.3.0'],
      );
    });
    test('tool, version, executables, hooks', () {
      var config = PubGlobalPackageConfig(
        package: 'p',
        tool: 'install',
        version: '^1.3.0',
        executables: ['a', 'b'],
        hooks: true,
      );
      var map = config.toMap();
      expect(map, {
        'package': 'p',
        'tool': 'install',
        'version': '^1.3.0',
        'executables': ['a', 'b'],
        'hooks': true,
      });
      var read = PubGlobalPackageConfig.fromMap(map);
      expect(read.toMap(), map);
      expect(read.toolOrNull, PubGlobalTool.install);
      expect(read.isHosted, isTrue);
      expect(read.activateArgs, [
        'p',
        '^1.3.0',
        '--executable',
        'a',
        '--executable',
        'b',
      ]);
      expect(
        read.copyWith(tool: 'activate').toolOrNull,
        PubGlobalTool.activate,
      );
      expect(
        PubGlobalPackageConfig(package: 'p', tool: 'bad').toolOrNull,
        isNull,
      );
      expect(PubGlobalTool.tryParse('activate'), PubGlobalTool.activate);
      expect(PubGlobalTool.activate.other, PubGlobalTool.install);
      expect(PubGlobalTool.names, ['activate', 'install']);
    });
  });
}
