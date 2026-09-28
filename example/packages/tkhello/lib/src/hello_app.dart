import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'launch_info.dart';
import 'marker.dart';

/// Runs a hello app named [packageName]: prints `Hello from <name>!`, the
/// [extra] lines (key: value), and with `--info` the launch diagnostics.
/// `--json` prints everything as one JSON object instead.
///
/// Returns the exit code.
Future<int> runHelloApp(
  List<String> arguments, {
  required String packageName,
  required String version,
  Future<Map<String, Object?>> Function()? extra,
}) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Usage help', negatable: false)
    ..addFlag('version', help: 'Display version', negatable: false)
    ..addFlag(
      'info',
      abbr: 'i',
      help: 'Print launch diagnostics',
      negatable: false,
    )
    ..addFlag(
      'json',
      help: 'Print everything as JSON (implies --info)',
      negatable: false,
    );
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: $packageName [options]');
    stdout.writeln(parser.usage);
    return 0;
  }
  if (results.flag('version')) {
    stdout.writeln('$packageName $version');
    return 0;
  }
  final json = results.flag('json');
  final info = json || results.flag('info');
  final extraValues = await extra?.call() ?? <String, Object?>{};
  final launchInfo = info
      ? LaunchInfo.current(executableName: packageName)
      : null;
  if (json) {
    final map = <String, Object?>{
      'name': packageName,
      'version': version,
      'marker': buildMarker,
      'hello': 'Hello from $packageName!',
      'extra': extraValues,
      'info': launchInfo!.toMap(),
    };
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(map));
    return 0;
  }
  stdout.writeln('Hello from $packageName!');
  for (final entry in extraValues.entries) {
    stdout.writeln('${entry.key}: ${entry.value}');
  }
  if (launchInfo != null) {
    stdout.writeln('$packageName $version (marker $buildMarker)');
    for (final line in launchInfo.toLines()) {
      stdout.writeln(line);
    }
  }
  return 0;
}
