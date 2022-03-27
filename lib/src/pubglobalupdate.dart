library pubglobalupdate;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/global_package.dart';

/// App version.
Version version = Version(1, 0, 1);

/// Update currently activated packages.
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
  final argResults = parser.parse(arguments);

  final help = argResults['help'] as bool;
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

  final showVersion = argResults['version'] as bool;
  if (showVersion) {
    stdout.writeln('pubglobalupdate version $version');
    return;
  }

  final dryRun = argResults['dry-run'] as bool;
  final verbose = argResults['verbose'] as bool;

  var result = await run('dart pub global list', verbose: verbose);
  var lines = result.outLines;

  final packages = argResults.rest;

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

      var cmd =
          'dart pub global activate ${package.activateArgs.map((e) => shellArgument(e)).join(' ')}';
      if (dryRun) {
        stdout.writeln(cmd);
      } else {
        stdout.writeln('updating: $package');
        result = await run(cmd, verbose: verbose);

        lines = result.outLines;
        for (final line in lines) {
          final updatedPackage =
              GlobalPackage.fromActivatedLine(line, package.name!);
          if (updatedPackage != null &&
              (verbose || (updatedPackage.version != package.version))) {
            stdout.writeln('updated: $updatedPackage');
          }
        }
      }
    }
  }
}
