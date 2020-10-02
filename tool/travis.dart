import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.');
  var shell = Shell();

  await shell.run('''
# dartdoc
dartdoc
''');
}
