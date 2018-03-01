#!/usr/bin/env dart
library pubglobalupdate;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/global_package.dart';

Version version = new Version(1, 0, 0);

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

///
/// Recursively update (pull) git folders
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('version', help: 'Display version', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag('dry-run',
      abbr: 'd',
      help: 'Do not run test, simple show the command executed',
      negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult['help'] as bool;
  if (help) {
    stdout.writeln("Update pub global activated package(s)");
    stdout.writeln();
    stdout.writeln('Usage: ${currentScriptName} [<pkg1> <pkg2>...]');
    stdout.writeln();
    stdout.writeln("By default all packages are updated");
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
    return;
  }

  bool showVersion = _argsResult['version'] as bool;
  if (showVersion) {
    stdout.writeln('${currentScriptName} version ${version}');
    return;
  }

  bool dryRun = _argsResult['dry-run'] as bool;
  bool verbose = _argsResult['verbose'] as bool;

  ProcessResult result =
      await runCmd(pubCmd(['global', 'list']), verbose: verbose);
  var lines = LineSplitter.split(result.stdout.toString());

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

      List<String> _pubArguments = <String>['global', 'activate']
        ..addAll(package.activateArgs);
      ProcessCmd cmd = pubCmd(_pubArguments);
      if (dryRun) {
        stdout.writeln(cmd);
      } else {
        stdout.writeln('updating: ${package}');
        result = await runCmd(cmd, verbose: verbose);
      }

      lines = LineSplitter.split(result.stdout.toString());
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
