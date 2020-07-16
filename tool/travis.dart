import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
# Formatting
dartfmt -n --set-exit-if-changed .
      
# Run tests
pub run test -p vm,chrome

# dartdoc
dartdoc
''');
}
