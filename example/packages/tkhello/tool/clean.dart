// Removes every trace of tkhello and tkhellohooks from both tools.
import 'dart:io';

import 'package:process_run/shell.dart';

import 'common.dart';

Future<void> main(List<String> arguments) async {
  final results = experimentArgParser().parse(arguments);
  for (final package in allPackages) {
    final x = Experiment(
      package: package,
      report: Report(),
      isolated: results.flag('isolated'),
      verbose: true,
    );
    final shell = Shell(
      environment: x.env,
      includeParentEnvironment: false,
      throwOnError: false,
    );
    await shell.run('''
dart pub global deactivate $package
dart uninstall $package
''');
    await x.restoreMarker();
    if (x.isolated && Directory(x.isolatedDir).existsSync()) {
      await Directory(x.isolatedDir).delete(recursive: true);
      stdout.writeln('deleted ${x.isolatedDir}');
    }
  }
}
