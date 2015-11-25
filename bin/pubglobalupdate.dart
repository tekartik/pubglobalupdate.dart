#!/usr/bin/env dart
library pubglobalupdate;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/dartbin_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:convert';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';

_insetString(String source, [int offset = 1]) {
  return source.substring(offset, source.length - offset);
}

///
/// remove enclosing " or '
///
_extractSource(String source) {
  if (source.startsWith('"') && source.endsWith('"')) {
    return _extractSource(_insetString(source));
  }
  if (source.startsWith("'") && source.endsWith("'")) {
    return _extractSource(_insetString(source));
  }
  return source;
}

///
/// Recursively update (pull) git folders
///
main(List<String> arguments) async {
  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN,
      abbr: 'd',
      help: 'Do not run test, simple show the command executed',
      negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    stdout.writeln("Update all pub package");
    stdout.writeln();
    stdout.writeln('Usage: pubglobalupdate [<pkg1> <pkg2>...]');
    stdout.writeln();
    stdout.writeln("""
By default all packages are updated
Global options:
""");
    stdout.writeln(parser.usage);
    return;
  }
  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    Logger.root.level = parseLogLevel(logLevel);
    Logger.root.info('Log level ${Logger.root.level}');
  }
  bool dryRun = _argsResult[_DRY_RUN];

  RunResult result = await runPub(['global', 'list'], connectIo: true);
  var lines = LineSplitter.split(result.out);

  List<String> packages = _argsResult.rest;

  for (String line in lines) {
    List<String> activateArgs;
    // Examples:
    // stagehand 0.2.4
    // tekartik_io_tools 0.7.1 from Git repository "https://github.com/alextekartik/tekartik_io_tools.dart"
    print(line);
    var parts = line.split(" ");
    // first is package name, last is path
    String name = parts.first;

    // Packages filtered?
    if (packages.isNotEmpty) {
      if (!packages.contains(name)) {
        continue;
      }
    }

    // ignore name
    if (parts.length == 2) {
      // hosted
      activateArgs = [name];
    }

    if (parts.length >= 5) {
      // handle git
      // tekartik_io_tools 0.7.1 from Git repository "https://github.com/alextekartik/tekartik_io_tools.dart"
      if (parts[3] == 'Git') {
        String source = _extractSource(parts.last);
        activateArgs = ['-s', 'git', source];
      } else {
        // path
        String sourceType = parts[parts.length - 2];
        String source = _extractSource(parts.last);
        if (sourceType == 'path') {
          activateArgs = ['-s', sourceType, source];
        }
      }
    }

    if (activateArgs != null) {
      await runPub(['global', 'activate']..addAll(activateArgs),
          cmdDryRun: dryRun, connectIo: true, workingDirectory: ".");
    } else {
      stderr.writeln('Not supported: ${line}');
    }
  }
}
