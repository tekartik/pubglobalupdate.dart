import 'package:dev_build/shell.dart';

import 'pub_global_deactivate.dart';

Future<void> main(List<String> args) async {
  await deactivatePubglobalUpdate();

  await run('dart pub global activate --source path .');
}
