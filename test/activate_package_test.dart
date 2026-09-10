import 'package:dev_build/package.dart';
import 'package:pubglobalupdate/pubglobalupdate.dart';
import 'package:test/test.dart';

/// True when running on the vm (io), false on browser and node.
const isIo = bool.fromEnvironment('dart.library.io');

void main() {
  group('activate_package', () {
    test('activatePackage', () async {
      // Typed argument even if null to make sure the signature is valid on
      // every platform.
      PubGlobalPackage? existingPackage;
      Future<void> doActivate() => activatePackage(
        'tekartik_pubglobalupdate_test_package',
        dryRun: true,
        existingPackage: existingPackage,
      );
      if (isIo) {
        // Dry run only prints the command.
        await doActivate();
      } else {
        await expectLater(doActivate(), throwsUnimplementedError);
      }
    });
  });
}
