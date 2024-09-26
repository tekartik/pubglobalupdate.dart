@TestOn('vm')
library;

import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/global_package.dart';
import 'package:test/test.dart';

void main() {
  group('global_package', () {
    test('hosted', () {
      // pub global activate markdown
      final line = 'markdown 0.9.0';
      var package = GlobalPackage.fromListLine(line) as GlobalHostedPackage;
      expect(package.name, 'markdown');
      expect(package.version, Version(0, 9, 0));
      expect(package.activateArgs, ['markdown']);

      final activatedLine = 'Activated markdown 0.10.0.';
      package = GlobalPackage.fromActivatedLine(activatedLine, package.name!)
          as GlobalHostedPackage;
      expect(package.name, 'markdown');
      expect(package.version, Version(0, 10, 0));
      expect(package.activateArgs, ['markdown']);

      expect(GlobalPackage.fromActivatedLine(activatedLine, 'dummy'), isNull);
    });

    test('git', () {
      // pub global activate --source git https://github.com/tekartik/pubglobalupdate.dart
      final line =
          "pubglobalupdate 0.1.0 from Git repository 'https://github.com/tekartik/pubglobalupdate.dart'";
      final package = GlobalPackage.fromListLine(line) as GlobalGitPackage;
      expect(package.name, 'pubglobalupdate');
      expect(package.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      expect(
          package.source, 'https://github.com/tekartik/pubglobalupdate.dart');
      expect(package.activateArgs, [
        '--source',
        'git',
        'https://github.com/tekartik/pubglobalupdate.dart'
      ]);
    });

    test('path', () {
      // pub global activate --source path /media/ssd/devx/git/bitbucket.org/alextk/script.dart
      final line =
          'tekartik_script 0.1.0 at path "/media/ssd/devx/git/bitbucket.org/alextk/script.dart"';
      final package = GlobalPackage.fromListLine(line) as GlobalPathPackage;
      expect(package.name, 'tekartik_script');
      expect(package.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      expect(package.source,
          '/media/ssd/devx/git/bitbucket.org/alextk/script.dart');
      expect(package.activateArgs, [
        '--source',
        'path',
        '/media/ssd/devx/git/bitbucket.org/alextk/script.dart'
      ]);
    });
  });
}
