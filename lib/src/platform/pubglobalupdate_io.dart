library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubglobalupdate/src/config.dart';
import 'package:pubglobalupdate/src/global_package.dart';
import 'package:pubglobalupdate/src/version.dart';

/// App version.
final version = packageVersion;

/// Update currently activated packages.
Future main(List<String> arguments) async {
  //setupQuickLogging();

  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('version', help: 'Display version', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addOption(
    'config-package',
    help: 'Configure package source (using git url path and ref)',
  );
  parser.addFlag(
    'config-read',
    help: 'Read package config (config-package options must be set)',
    negatable: false,
  );
  parser.addFlag(
    'config-clear',
    help: 'Clear package config (config-package options must be set)',
    negatable: false,
  );
  parser.addFlag(
    'config-list',
    help: 'List all package configuration',
    negatable: false,
  );
  parser.addFlag(
    'package-list',
    help: 'List all packages configured',
    negatable: false,
  );
  parser.addFlag(
    'install',
    help: 'Install package if not already activated',
    negatable: false,
  );
  parser.addOption(
    'source',
    help: 'Config source',
    allowed: ['git', 'path', 'hosted'],
  );
  parser.addOption('git-url', help: 'Git url');
  parser.addOption('git-path', help: 'Git path');
  parser.addOption('git-ref', help: 'Git ref');
  parser.addFlag(
    'dry-run',
    abbr: 'd',
    help: 'Do not run test, simple show the command executed',
    negatable: false,
  );
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

  var listConfig = argResults.flag('config-list');
  var listPackages = argResults.flag('package-list');
  if (listConfig || listPackages) {
    for (var package in await listConfiguredPackages()) {
      if (listPackages) {
        stdout.writeln(package);
      } else {
        stdout.writeln('$package:');
        var config = await readConfig(package);
        if (config != null) {
          stdout.writeln(
            const JsonEncoder.withIndent('  ').convert(config.toMap()),
          );
        }
      }
    }
    return;
  }
  var configPackage = argResults['config-package'] as String?;
  if (configPackage != null) {
    var read = argResults.flag('config-read');
    if (read) {
      var config = await readConfig(configPackage);
      if (config != null) {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(config.toMap()),
        );
      }
      return;
    }
    var clear = argResults.flag('config-clear');
    if (clear) {
      await deleteConfig(configPackage);
      return;
    }
    var gitUrl = argResults['git-url'] as String?;
    var gitPath = argResults['git-path'] as String?;
    var gitRef = argResults['git-ref'] as String?;
    var source = argResults['source'] as String?;
    var config = GlobalPackageConfig(
      package: configPackage,
      source: source,
      gitUrl: gitUrl,
      gitPath: gitPath,
      gitRef: gitRef,
    );
    await writeConfig(configPackage, config);

    return;
  }
  if (argResults.flag('config-read')) {
    stderr.writeln('config-package must be set');
    exit(1);
  }
  if (argResults.flag('config-clear')) {
    stderr.writeln('config-package must be set');
    exit(1);
  }

  var result = await run('dart pub global list', verbose: verbose);
  var lines = result.outLines;
  final install = argResults.flag('install');
  final packages = argResults.rest;

  if (install) {
    for (var package in packages) {
      await activatePackage(package);
    }
    return;
  }
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

      var packageName = package.name!;
      await activatePackage(
        packageName,
        dryRun: dryRun,
        verbose: verbose,
        existingPackage: package,
      );
    }
  }
}

/// Activate package according its saved configuration if any
Future<void> activatePackage(
  String packageName, {

  /// Set when updating
  bool? dryRun,
  bool? verbose,

  /// Resolved from command line
  GlobalPackage? existingPackage,
}) async {
  dryRun ??= false;
  verbose ??= false;
  var savedConfig = await readConfig(packageName);
  var existingPackageVersion = existingPackage?.version;
  String cmd;
  if (savedConfig != null) {
    cmd = 'dart pub global activate ${savedConfig.toActivateArgsString()}';
  } else if (existingPackage != null) {
    cmd =
        'dart pub global activate ${existingPackage.activateArgs.map((e) => shellArgument(e)).join(' ')}';
  } else {
    cmd = 'dart pub global activate $packageName';
  }
  var installing = existingPackageVersion == null;
  if (dryRun) {
    stdout.writeln(cmd);
  } else {
    stdout.writeln('${installing ? 'installing' : 'updating'}: $packageName');
    final result = await run(cmd, verbose: verbose);

    final lines = result.outLines;
    for (final line in lines) {
      final updatedPackage = GlobalPackage.fromActivatedLine(line, packageName);
      if (updatedPackage != null &&
          (verbose ||
              (updatedPackage.version !=
                  (existingPackageVersion ?? Version(0, 0, 0))))) {
        stdout.writeln(
          '${installing ? 'installed' : 'updated'}: $updatedPackage',
        );
      }
    }
  }
}
