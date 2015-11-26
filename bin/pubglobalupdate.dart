#!/usr/bin/env dart
library pubglobalupdate;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:cmdo/cmdo_io.dart';
import 'package:cmdo/cmdo_dry.dart';
import 'package:cmdo/dartbin.dart';
import 'dart:convert';
import 'package:pubglobalupdate/global_package.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';
const String _VERBOSE = 'verbose';

///
/// Recursively update (pull) git folders
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  //parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_VERBOSE, abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag(_DRY_RUN,
      abbr: 'd',
      help: 'Do not run test, simple show the command executed',
      negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
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
  bool dryRun = _argsResult[_DRY_RUN];
  bool verbose = _argsResult[_VERBOSE];

  CommandResult result =
      await io.runInput(pubCmd(['global', 'list'])..connectIo = verbose);
  var lines = LineSplitter.split(result.out);

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

      CommandExecutor cmdo;
      if (dryRun) {
        cmdo = dry;
      } else {
        cmdo = io;
      }
      stdout.writeln('updating: ${package}');
      result = await cmdo.runInput(
          pubCmd(['global', 'activate']..addAll(package.activateArgs))
            ..connectIo = verbose || dryRun);

      for (String line in result.output.outLines) {
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
