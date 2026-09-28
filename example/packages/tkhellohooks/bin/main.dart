import 'dart:io';

import 'package:tkhello/tkhello.dart';
import 'package:tkhellohooks/tkhellohooks.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runHelloApp(
    arguments,
    packageName: 'tkhellohooks',
    version: tkhellohooksVersion,
    extra: () async => {'sqlite version': await getSqliteVersion()},
  );
}
