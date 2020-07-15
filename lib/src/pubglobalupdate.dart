#!/usr/bin/env dart

library pubglobalupdate;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/global_package.dart';

/// App version.
Version version = Version(1, 0, 1);

///
/// Recursively update (pull) git folders
///
Future main(List<String> arguments) async {
  //setupQuickLogging();

  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('version', help: 'Display version', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addFlag('dry-run',
      abbr: 'd',
      help: 'Do not run test, simple show the command executed',
      negatable: false);
  final _argsResult = parser.parse(arguments);

  final help = _argsResult['help'] as bool;
  if (help) {
    stdout.writeln('Update pub global activated package(s)');
    stdout.writeln();
    stdout.writeln('Usage: pubglobalupdate [<pkg1> <pkg2>...]');
    stdout.writeln();
    stdout.writeln('By default all packages are updated');
    stdout.writeln();
    stdout.writeln('Global options:');
    stdout.writeln(parser.usage);
    return;
  }

  final showVersion = _argsResult['version'] as bool;
  if (showVersion) {
    stdout.writeln('pubglobalupdate version ${version}');
    return;
  }

  final dryRun = _argsResult['dry-run'] as bool;
  final verbose = _argsResult['verbose'] as bool;

  var result = await runCmd(PubCmd(['global', 'list']), verbose: verbose);
  var lines = LineSplitter.split(result.stdout.toString());

  final packages = _argsResult.rest;

  for (final line in lines) {
    final package = GlobalPackage.fromListLine(line);
    if (package == null) {
      stderr.writeln("Cannot parse package information '$line'");
    } else {
      // Packages filtered?
      if (packages.isNotEmpty) {
        if (!packages.contains(package.name)) {
          continue;
        }
      }

      final _pubArguments = <String>[
        'global',
        'activate',
        ...package.activateArgs
      ];
      ProcessCmd cmd = PubCmd(_pubArguments);
      if (dryRun) {
        stdout.writeln(cmd);
      } else {
        stdout.writeln('updating: ${package}');
        result = await runCmd(cmd, verbose: verbose);
      }

      lines = LineSplitter.split(result.stdout.toString());
      for (final line in lines) {
        final updatedPackage =
            GlobalPackage.fromActivatedLine(line, package.name);
        if (updatedPackage != null &&
            (verbose || (updatedPackage.version != package.version))) {
          stdout.writeln('updated: ${updatedPackage}');
        }
      }
    }
  }
}
