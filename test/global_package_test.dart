import 'package:dev_test/test.dart';

import 'package:pubglobalupdate/global_package.dart';
import 'package:pub_semver/pub_semver.dart';

main() {
  group('global_package', () {
    test('hosted', () {
      // pub global activate markdown
      String line = "markdown 0.9.0";
      GlobalHostedPackage package = GlobalPackage.fromListLine(line);
      expect(package.name, "markdown");
      expect(package.version, new Version(0, 9, 0));
      expect(package.activateArgs, ['markdown']);

      String activatedLine = "Activated markdown 0.10.0.";
      package = GlobalPackage.fromActivatedLine(activatedLine, package.name);
      expect(package.name, "markdown");
      expect(package.version, new Version(0, 10, 0));
      expect(package.activateArgs, ['markdown']);

      expect(GlobalPackage.fromActivatedLine(activatedLine, "dummy"), isNull);
    });

    test('git', () {
      // pub global activate --source git https://github.com/tekartik/pubglobalupdate.dart
      String line =
          'pubglobalupdate 0.1.0 from Git repository "https://github.com/tekartik/pubglobalupdate.dart"';
      GlobalGitPackage package = GlobalPackage.fromListLine(line);
      expect(package.name, "pubglobalupdate");
      expect(package.version, greaterThanOrEqualTo(new Version(0, 1, 0)));
      expect(
          package.source, "https://github.com/tekartik/pubglobalupdate.dart");
      expect(package.activateArgs, [
        '--source',
        'git',
        "https://github.com/tekartik/pubglobalupdate.dart"
      ]);
    });

    test('path', () {
      // pub global activate --source path /media/ssd/devx/git/bitbucket.org/alextk/script.dart
      String line =
          'tekartik_script 0.1.0 at path "/media/ssd/devx/git/bitbucket.org/alextk/script.dart"';
      GlobalPathPackage package = GlobalPackage.fromListLine(line);
      expect(package.name, "tekartik_script");
      expect(package.version, greaterThanOrEqualTo(new Version(0, 1, 0)));
      expect(package.source,
          "/media/ssd/devx/git/bitbucket.org/alextk/script.dart");
      expect(package.activateArgs, [
        '--source',
        'path',
        "/media/ssd/devx/git/bitbucket.org/alextk/script.dart"
      ]);
    });
  });
}
