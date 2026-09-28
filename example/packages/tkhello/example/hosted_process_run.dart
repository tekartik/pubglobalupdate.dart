// Manual hosted example: installs and activates a real public package
// (process_run, executable `ds`) with both tools, then removes it.
//
// Run by hand only, never by matrix.dart or the tests:
//   dart run example/hosted_process_run.dart --yes
// Without --yes it only prints the commands.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

const package = 'process_run';
const exe = 'ds';

Future<void> main(List<String> arguments) async {
  final paths = dartToolPaths;
  final bat = Platform.isWindows ? '.bat' : '';
  final binstub = p.join(paths.pubCacheBinPath, '$exe$bat');
  final link = p.join(paths.dartInstallBinPath, '$exe$bat');
  final script =
      '''
# pub global, hosted
dart pub global activate $package --overwrite
dart pub global activate $package ^1.3.0 --overwrite
dart pub global list
${shellArgument(binstub)} --version
dart pub global deactivate $package
# dart install, hosted
dart install $package --overwrite
dart install $package@^1.3.0
dart installed
dart installed --all
${shellArgument(link)} --version
dart uninstall $package
dart installed --all
''';
  if (!arguments.contains('--yes')) {
    stdout.writeln('Would run (add --yes):\n$script');
    return;
  }
  await Shell(throwOnError: false).run(script);
}
