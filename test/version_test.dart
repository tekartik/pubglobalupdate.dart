import 'package:process_run/process_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/version.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('version', () async {
    var outVersion = Version.parse(
      (await run(
        'dart run bin/pubglobalupdate.dart --version',
      )).outText.trim().split(' ').firstWhere((text) {
        try {
          Version.parse(text);
          return true;
        } catch (_) {
          return false;
        }
      }),
    );
    expect(outVersion, packageVersion);
  });
}
