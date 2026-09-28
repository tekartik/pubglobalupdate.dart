import 'dart:io';

import 'package:tkhello/tkhello.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runHelloApp(
    arguments,
    packageName: 'tkhello',
    version: tkhelloVersion,
  );
}
