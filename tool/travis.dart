import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var shell = Shell();

  // Formatting change in 2.9 with hashbang first line
  if (dartVersion >= Version(2, 9, 0, pre: '0')) {
    await shell.run('''
      # Formatting
      dartfmt -n --set-exit-if-changed .
    ''');
  }

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .

# Run tests
pub run test -p vm,chrome

# dartdoc
dartdoc
''');
}
