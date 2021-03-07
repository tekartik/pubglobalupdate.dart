import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

var minNnbdVersion = Version(2, 12, 0, pre: '0');

Future main() async {
  var nnbdEnabled = dartVersion > minNnbdVersion;
  if (nnbdEnabled) {
    await packageRunCi('.');
    var shell = Shell();

    await shell.run('''
# dartdoc
dartdoc
''');
  }
}
