import 'package:pubglobalupdate/src/config.dart';
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
  });
}
