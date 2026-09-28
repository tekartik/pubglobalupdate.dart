import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/dart_installed_package.dart';
import 'package:test/test.dart';

void main() {
  group('dart_installed_package', () {
    test('hosted', () {
      final package = DartInstalledPackage.fromListLine('webdev 4.0.3')!;
      expect(package.name, 'webdev');
      expect(package.version, Version(4, 0, 3));
      expect(package.source, 'hosted');
      expect(package.active, isTrue);
      expect(package.installArgs, ['webdev']);
      expect(package.activateArgs, ['webdev']);
      expect(package.toString(), 'webdev 4.0.3');
    });
    test('git', () {
      final package = DartInstalledPackage.fromListLine(
        'tkhello 1.0.0 from Git repository "file:///repo/x.dart" at "c2da1061"',
      )!;
      expect(package.source, 'git');
      expect(package.gitUrl, 'file:///repo/x.dart');
      expect(package.gitRef, 'c2da1061');
      expect(package.installArgs, [
        'tkhello@{git: {url: file:///repo/x.dart}}',
      ]);
      expect(package.activateArgs, ['--source', 'git', 'file:///repo/x.dart']);
    });
    test('path', () {
      final package = DartInstalledPackage.fromListLine(
        'tkhello 1.0.0 from "/home/u/example/packages/tkhello" at 2026-09-28 17:06:49.116900',
      )!;
      expect(package.source, 'path');
      expect(package.path, '/home/u/example/packages/tkhello');
      expect(package.lastModified, '2026-09-28 17:06:49.116900');
      expect(package.installArgs, [
        'tkhello@{path: /home/u/example/packages/tkhello}',
      ]);
      expect(package.activateArgs, [
        '--source',
        'path',
        '/home/u/example/packages/tkhello',
      ]);
    });
    test('not active', () {
      final package = DartInstalledPackage.fromListLine(
        'dev_build 1.1.9 (not active)',
      )!;
      expect(package.status, 'not active');
      expect(package.active, isFalse);
      expect(package.version, Version(1, 1, 9));
      expect(package.toString(), 'dev_build 1.1.9 (not active)');
      final path = DartInstalledPackage.fromListLine(
        'x 1.0.0 from "/p (1)" at 2026-09-28 17:06:49.116900 (not active)',
      )!;
      expect(path.path, '/p (1)');
      expect(path.active, isFalse);
    });
    test('unknown / invalid', () {
      expect(
        DartInstalledPackage.fromListLine(
          'x 1.0.0 from an unknown source "sdk"',
        )!.source,
        'unknown',
      );
      expect(DartInstalledPackage.fromListLine(''), isNull);
      expect(
        DartInstalledPackage.fromListLine('No Dart CLI tools installed.'),
        isNull,
      );
      expect(DartInstalledPackage.fromListLine('x notaversion'), isNull);
      expect(DartInstalledPackage.fromListLine('x 1.0.0 from nowhere'), isNull);
    });
  });
}
