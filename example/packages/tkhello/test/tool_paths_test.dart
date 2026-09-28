import 'package:test/test.dart';
import 'package:tkhello/tkhello.dart';

void main() {
  group('linux', () {
    final paths = ToolPaths(
      os: ToolOs.linux,
      environment: {
        'HOME': '/home/u',
        'PATH':
            '/home/u/.pub-cache/bin:/usr/bin:/home/u/.local/state/Dart/install/bin/',
      },
    );
    test('defaults', () {
      expect(paths.pubCachePath, '/home/u/.pub-cache');
      expect(paths.pubCacheBinPath, '/home/u/.pub-cache/bin');
      expect(paths.dartDataHomePath, '/home/u/.local/state/Dart');
      expect(paths.dartInstallPath, '/home/u/.local/state/Dart/install');
      expect(paths.dartInstallBinPath, '/home/u/.local/state/Dart/install/bin');
      expect(
        paths.dartInstallAppBundlesPath,
        '/home/u/.local/state/Dart/install/app-bundles',
      );
    });
    test('path', () {
      expect(paths.pathIndexOf('/home/u/.pub-cache/bin'), 0);
      // Trailing separator ignored
      expect(paths.pathIndexOf('/home/u/.local/state/Dart/install/bin'), 2);
      expect(paths.isDirOnPath('/opt/bin'), isFalse);
      expect(
        paths.findOnPath('x', exists: (path) => path == '/usr/bin/x'),
        '/usr/bin/x',
      );
      expect(paths.findOnPath('x', exists: (_) => false), isNull);
    });
    test('overrides', () {
      final overridden = ToolPaths(
        os: ToolOs.linux,
        environment: {
          'HOME': '/home/u',
          'PUB_CACHE': '/tmp/cache',
          'DART_DATA_HOME': '/tmp/data',
        },
      );
      expect(overridden.pubCacheBinPath, '/tmp/cache/bin');
      expect(overridden.dartInstallBinPath, '/tmp/data/install/bin');
      final xdg = ToolPaths(
        os: ToolOs.linux,
        environment: {'HOME': '/home/u', 'XDG_STATE_HOME': '/state'},
      );
      expect(xdg.dartInstallBinPath, '/state/Dart/install/bin');
    });
  });

  test('macos', () {
    final paths = ToolPaths(
      os: ToolOs.macos,
      environment: {'HOME': '/Users/u'},
    );
    expect(paths.pubCacheBinPath, '/Users/u/.pub-cache/bin');
    expect(
      paths.dartInstallBinPath,
      '/Users/u/Library/Application Support/Dart/install/bin',
    );
  });

  test('windows', () {
    final paths = ToolPaths(
      os: ToolOs.windows,
      environment: {
        'USERPROFILE': r'C:\Users\u',
        'LocalAppData': r'C:\Users\u\AppData\Local',
        'Path': r'C:\Users\u\AppData\Local\Pub\Cache\bin;C:\Windows',
      },
    );
    expect(paths.pubCacheBinPath, r'C:\Users\u\AppData\Local\Pub\Cache\bin');
    expect(
      paths.dartInstallBinPath,
      r'C:\Users\u\AppData\Local\Dart\install\bin',
    );
    // Case insensitive
    expect(paths.pathIndexOf(r'c:\users\u\appdata\local\pub\cache\bin'), 0);
    expect(
      paths.findOnPath('x', exists: (path) => path == r'C:\Windows\x.bat'),
      r'C:\Windows\x.bat',
    );
  });
}
