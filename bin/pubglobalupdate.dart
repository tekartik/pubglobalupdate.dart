#!/usr/bin/env dart
library pubglobalupdate;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';
import 'dart:convert';
import 'package:pubglobalupdate/global_package.dart';

///
/// Recursively update (pull) git folders
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  //parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag('dry-run',
      abbr: 'd',
      help: 'Do not run test, simple show the command executed',
      negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult['help'];
  if (help) {
    stdout.writeln("Update pub global activated package(s)");
    stdout.writeln();
    stdout.writeln('Usage: pubglobalupdate [<pkg1> <pkg2>...]');
    stdout.writeln();
    stdout.writeln("By default all packages are updated");
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
    return;
  }
  /*
  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    Logger.root.level = parseLogLevel(logLevel);
    Logger.root.info('Log level ${Logger.root.level}');
  }
  */
  bool dryRun = _argsResult['dry-run'];
  bool verbose = _argsResult['verbose'];

  ProcessResult result = await run(
      dartExecutable, pubArguments(['global', 'list']),
      connectStdout: verbose, connectStderr: verbose);
  var lines = LineSplitter.split(result.stdout);

  List<String> packages = _argsResult.rest;

  for (String line in lines) {
    GlobalPackage package = GlobalPackage.fromListLine(line);
    if (package == null) {
      stderr.writeln("Cannot parse package information '$line'");
    } else {
      // Packages filtered?
      if (packages.isNotEmpty) {
        if (!packages.contains(package.name)) {
          continue;
        }
      }

      List<String> _pubArguments = ['global', 'activate']..addAll(package.activateArgs);
      List<String> arguments = pubArguments(_pubArguments);
      if (dryRun) {
        stdout.writeln(executableArgumentsToString('pub', _pubArguments));
      } else {
        stdout.writeln('updating: ${package}');
        result = await run(dartExecutable, arguments,
            connectStdout: verbose, connectStderr: verbose);
      }

      lines = LineSplitter.split(result.stdout);
      for (String line in lines) {
        GlobalPackage updatedPackage =
            GlobalPackage.fromActivatedLine(line, package.name);
        if (updatedPackage != null &&
            (verbose || (updatedPackage.version != package.version))) {
          stdout.writeln('updated: ${updatedPackage}');
        }
      }
    }
  }
}
