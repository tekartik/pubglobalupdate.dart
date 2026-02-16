import 'package:dev_build/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  await packageRunCi('.');
  var shell = Shell();

  await shell.run('''
# dart doc
dart doc .
''');
}
