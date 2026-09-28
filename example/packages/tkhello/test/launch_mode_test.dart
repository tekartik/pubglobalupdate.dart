import 'package:test/test.dart';
import 'package:tkhello/tkhello.dart';

void main() {
  const dart = '/sdk/bin/dart';
  LaunchMode detect(String script, {String executable = dart}) =>
      detectLaunchMode(
        script: script,
        executable: executable,
        resolvedExecutable: executable,
      );
  test('detectLaunchMode', () {
    expect(
      detect(
        '/home/u/.pub-cache/global_packages/tkhello/bin/main.dart-3.13.3.snapshot',
      ),
      LaunchMode.pubGlobalBinstub,
    );
    expect(
      detect(
        r'C:\Users\u\AppData\Local\Pub\Cache\global_packages\tkhello\bin\main.dart-3.13.3.snapshot',
      ),
      LaunchMode.pubGlobalBinstub,
    );
    expect(
      detect('/repo/.dart_tool/pub/bin/tkhello/main.dart-3.13.3.snapshot'),
      LaunchMode.jitSnapshot,
    );
    expect(
      detect('/repo/example/packages/tkhello/bin/main.dart'),
      LaunchMode.dartScript,
    );
    expect(
      detect(
        '/home/u/.local/state/Dart/install/app-bundles/tkhello/local/bundle/bin/tkhello',
        executable:
            '/home/u/.local/state/Dart/install/app-bundles/tkhello/local/bundle/bin/tkhello',
      ),
      LaunchMode.dartInstall,
    );
    // Verified on Linux: script and executable are the link in install/bin,
    // only resolvedExecutable points inside the app bundle.
    expect(
      detectLaunchMode(
        script: '/home/u/.local/state/Dart/install/bin/tkhello',
        executable: '/home/u/.local/state/Dart/install/bin/tkhello',
        resolvedExecutable:
            '/home/u/.local/state/Dart/install/app-bundles/tkhello/local/bundle/bin/tkhello',
      ),
      LaunchMode.dartInstall,
    );
    expect(
      detect('/tmp/tkhello', executable: '/tmp/tkhello'),
      LaunchMode.aotExecutable,
    );
  });
}
