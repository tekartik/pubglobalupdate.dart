library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:pubglobalupdate/src/config.dart';
import 'package:pubglobalupdate/src/io/global_tool_package.dart';
import 'package:pubglobalupdate/src/settings.dart';
import 'package:pubglobalupdate/src/tool.dart';
import 'package:pubglobalupdate/src/version.dart';

export 'package:pubglobalupdate/src/io/global_tool_package.dart'
    show GlobalToolPackage, listGlobalToolPackages;

/// App version.
final version = packageVersion;

/// Update currently activated and installed packages.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('version', help: 'Display version', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addOption(
    'config-package',
    help: 'Configure package source (using git url path and ref) and tool',
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
    help: 'List all package configuration and the settings',
    negatable: false,
  );
  parser.addFlag(
    'package-list',
    help: 'List all packages configured',
    negatable: false,
  );
  parser.addFlag(
    'install',
    help: 'Install package if not already activated/installed',
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
  parser.addOption('path', help: 'Path for path source');
  parser.addOption(
    'version-constraint',
    help: 'Config version constraint for a hosted source (^1.0.0)',
  );
  parser.addMultiOption(
    'executable',
    abbr: 'x',
    help: 'Config executable(s) to put on PATH (activate only)',
  );
  parser.addFlag(
    'hooks',
    help: 'Config: the package needs build hooks, so dart install',
    negatable: false,
  );
  parser.addOption(
    'tool',
    help:
        'The tool: activate (dart pub global activate) or install '
        '(dart install). Saved with --config-package, one-off otherwise',
    allowed: PubGlobalTool.names,
  );
  parser.addOption(
    'default-tool',
    help: 'Save the tool used for packages without a configured tool',
    allowed: PubGlobalTool.names,
  );
  parser.addFlag(
    'list',
    help: 'List the packages of both tools',
    negatable: false,
  );
  parser.addFlag(
    'all',
    help: 'With --list: include inactive dart install bundles',
    negatable: false,
  );
  parser.addFlag(
    'migrate',
    help:
        'Move package(s) to the other tool (or the one given by --tool or '
        'the config), keeping the config',
    negatable: false,
  );
  parser.addFlag(
    'doctor',
    help: 'Check the bin directories, PATH, duplicates and configs',
    negatable: false,
  );
  parser.addFlag(
    'dry-run',
    abbr: 'd',
    help: 'Do not run test, simple show the command executed',
    negatable: false,
  );
  final argResults = parser.parse(arguments);

  final help = argResults['help'] as bool;
  if (help) {
    stdout.writeln('Update pub global activated and dart installed package(s)');
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
  final toolOption = PubGlobalTool.tryParse(argResults.option('tool'));

  var defaultTool = argResults.option('default-tool');
  if (defaultTool != null) {
    await writeSettings(PubGlobalSettings(defaultTool: defaultTool));
    stdout.writeln('default tool: $defaultTool');
    return;
  }

  var listConfig = argResults.flag('config-list');
  var listPackages = argResults.flag('package-list');
  if (listConfig || listPackages) {
    if (listConfig) {
      final settings = await readSettings();
      stdout.writeln(
        'settings: ${const JsonEncoder.withIndent('  ').convert(settings.toMap())}',
      );
    }
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
    var gitUrl = argResults.option('git-url');
    var gitPath = argResults.option('git-path');
    var gitRef = argResults.option('git-ref');
    var source = argResults.option('source');
    var path = argResults.option('path');
    if (source == 'git') {
      if (gitUrl == null) {
        stderr.writeln('git-url must be set');

        exit(1);
      }
    } else if (source == 'path') {
      if (path == null) {
        stderr.writeln('path must be set');

        exit(1);
      }
    } else if (source == 'hosted' || source == null) {
      // hosted is default
    } else {
      stderr.writeln('Invalid source $source');

      exit(1);
    }
    var executables = argResults.multiOption('executable');
    var config = PubGlobalPackageConfig(
      package: configPackage,
      path: path,
      source: source,
      gitUrl: gitUrl,
      gitPath: gitPath,
      gitRef: gitRef,
      tool: toolOption?.name,
      version: argResults.option('version-constraint'),
      executables: executables.isEmpty ? null : executables,
      hooks: argResults.flag('hooks') ? true : null,
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

  if (argResults.flag('doctor')) {
    await doctor(verbose: verbose);
    return;
  }
  if (argResults.flag('list')) {
    final packages = await listGlobalToolPackages(
      includeInactive: argResults.flag('all'),
      verbose: verbose,
    );
    for (final package in packages) {
      stdout.writeln(package);
    }
    return;
  }

  final packages = argResults.rest;
  final install = argResults.flag('install');
  if (install) {
    for (var package in packages) {
      await installPackage(
        package,
        tool: toolOption,
        dryRun: dryRun,
        verbose: verbose,
      );
    }
    return;
  }
  if (argResults.flag('migrate')) {
    if (packages.isEmpty) {
      stderr.writeln('--migrate needs package name(s)');
      exit(1);
    }
    for (var package in packages) {
      await migratePackage(
        package,
        tool: toolOption,
        dryRun: dryRun,
        verbose: verbose,
      );
    }
    return;
  }

  final installed = await listGlobalToolPackages(verbose: verbose);
  for (final package in installed) {
    // Packages filtered?
    if (packages.isNotEmpty && !packages.contains(package.name)) {
      continue;
    }
    if (toolOption != null && package.tool != toolOption) {
      continue;
    }
    await updatePackage(package, dryRun: dryRun, verbose: verbose);
  }
}

String _activateCommand(List<String> args) =>
    'dart pub global activate ${shellArguments(args)}';

String _installCommand(List<String> args) =>
    'dart install ${shellArguments(args)} --overwrite';

/// Runs [cmd], prints `installed:`/`updated:` lines.
Future<void> _runToolCommand(
  String cmd, {
  required String packageName,
  required PubGlobalTool tool,
  required bool installing,
  required bool dryRun,
  required bool verbose,
  Version? existingVersion,
}) async {
  if (dryRun) {
    stdout.writeln(cmd);
    return;
  }
  stdout.writeln(
    '${installing ? 'installing' : 'updating'}: $packageName ($tool)',
  );
  final result = await run(cmd, verbose: verbose);
  final lines = result.outLines;
  if (tool == PubGlobalTool.activate) {
    for (final line in lines) {
      final updatedPackage = PubGlobalPackage.fromActivatedLine(
        line,
        packageName,
      );
      if (updatedPackage != null &&
          (verbose ||
              (updatedPackage.version !=
                  (existingVersion ?? Version(0, 0, 0))))) {
        stdout.writeln(
          '${installing ? 'installed' : 'updated'}: $updatedPackage',
        );
      }
    }
  } else {
    for (final line in lines) {
      if (line.startsWith('Installed: ')) {
        stdout.writeln(
          '${installing ? 'installed' : 'updated'}: $packageName '
          '${line.substring('Installed: '.length)}',
        );
      }
    }
  }
}

/// Activate package according its saved configuration if any
/// (`dart pub global activate` only, see [installPackage] for the tool
/// choice).
Future<void> activatePackage(
  String packageName, {

  /// Set when updating
  bool? dryRun,
  bool? verbose,

  /// Resolved from command line
  PubGlobalPackage? existingPackage,
}) async {
  dryRun ??= false;
  verbose ??= false;
  var savedConfig = await readConfig(packageName);
  final args =
      savedConfig?.activateArgs ??
      existingPackage?.activateArgs ??
      [packageName];
  await _runToolCommand(
    _activateCommand(args),
    packageName: packageName,
    tool: PubGlobalTool.activate,
    installing: existingPackage?.version == null,
    dryRun: dryRun,
    verbose: verbose,
    existingVersion: existingPackage?.version,
  );
}

/// The tool for a first install of [packageName]: [tool] (command line),
/// else the config `tool`, else `install` when the config says `hooks`,
/// else the settings default, else `activate`.
Future<PubGlobalTool> resolveTool(
  String packageName, {
  PubGlobalTool? tool,
  PubGlobalPackageConfig? config,
}) async {
  if (tool != null) {
    return tool;
  }
  final configTool = config?.toolOrNull;
  if (configTool != null) {
    return configTool;
  }
  if (config?.hooks == true) {
    return PubGlobalTool.install;
  }
  return (await readSettings()).defaultToolOrDefault;
}

/// Install [packageName] with [tool] (see [resolveTool]) using its saved
/// config if any.
Future<void> installPackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async {
  dryRun ??= false;
  verbose ??= false;
  final config = await readConfig(packageName);
  final resolved = await resolveTool(packageName, tool: tool, config: config);
  final String cmd;
  if (resolved == PubGlobalTool.activate) {
    cmd = _activateCommand(config?.activateArgs ?? [packageName]);
  } else {
    cmd = _installCommand(config?.installArgs ?? [packageName]);
  }
  await _runToolCommand(
    cmd,
    packageName: packageName,
    tool: resolved,
    installing: true,
    dryRun: dryRun,
    verbose: verbose,
  );
}

/// Update [package] with the tool that owns it. A config asking for the
/// other tool only prints a `--migrate` hint: nothing is uninstalled here.
Future<void> updatePackage(
  GlobalToolPackage package, {
  bool? dryRun,
  bool? verbose,
}) async {
  dryRun ??= false;
  verbose ??= false;
  final config = await readConfig(package.name);
  final wanted = config?.toolOrNull;
  if (wanted != null && wanted != package.tool) {
    stdout.writeln(
      'hint: ${package.name} is installed with ${package.tool.command} but '
      'configured for ${wanted.command}, run: '
      'pubglobalupdate --migrate ${package.name}',
    );
  }
  final String cmd;
  if (package.tool == PubGlobalTool.activate) {
    cmd = _activateCommand(config?.activateArgs ?? package.updateArgs);
  } else {
    cmd = _installCommand(config?.installArgs ?? package.updateArgs);
  }
  await _runToolCommand(
    cmd,
    packageName: package.name,
    tool: package.tool,
    installing: false,
    dryRun: dryRun,
    verbose: verbose,
    existingVersion: package.version,
  );
}

/// Move [packageName] to [tool] (else the config tool, else the other
/// tool): remove it from its current tool, install it with the target using
/// the config if any (else the source reported by the list), then save the
/// tool in the config.
Future<void> migratePackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async {
  dryRun ??= false;
  verbose ??= false;
  final installed = (await listGlobalToolPackages(
    verbose: verbose,
  )).where((package) => package.name == packageName).toList();
  if (installed.isEmpty) {
    stderr.writeln(
      '$packageName is not installed, use --install [--tool <tool>]',
    );
    return;
  }
  final owners = installed.map((package) => package.tool).toSet();
  var config = await readConfig(packageName);
  final target =
      tool ??
      config?.toolOrNull ??
      (owners.length == 1 ? owners.first.other : null);
  if (target == null) {
    stderr.writeln(
      '$packageName is installed with both tools, pass --tool '
      '${PubGlobalTool.names.join('|')}',
    );
    return;
  }
  if (owners.length == 1 && owners.first == target) {
    stdout.writeln('$packageName is already installed with ${target.command}');
    return;
  }
  // Prefer a source from a package installed with the other tool.
  final from = installed.firstWhere(
    (package) => package.tool != target,
    orElse: () => installed.first,
  );
  for (final package in installed) {
    if (package.tool == target) {
      continue;
    }
    final cmd = package.tool == PubGlobalTool.activate
        ? 'dart pub global deactivate $packageName'
        : 'dart uninstall $packageName';
    if (dryRun) {
      stdout.writeln(cmd);
    } else {
      stdout.writeln('removing: $packageName (${package.tool})');
      await run(cmd, verbose: verbose);
    }
  }
  final String cmd;
  if (target == PubGlobalTool.activate) {
    cmd = _activateCommand(config?.activateArgs ?? from.otherToolArgs);
  } else {
    cmd = _installCommand(config?.installArgs ?? from.otherToolArgs);
  }
  await _runToolCommand(
    cmd,
    packageName: packageName,
    tool: target,
    installing: true,
    dryRun: dryRun,
    verbose: verbose,
  );
  if (!dryRun) {
    config ??= PubGlobalPackageConfig(
      package: packageName,
      source: from.source == 'hosted' ? null : from.source,
      gitUrl: from.source == 'git' ? from.sourceValue : null,
      path: from.source == 'path' ? from.sourceValue : null,
    );
    await writeConfig(packageName, config.copyWith(tool: target.name));
    stdout.writeln('config: $packageName tool ${target.name}');
  }
}

/// Checks the bin directories, PATH, packages present in both tools,
/// inactive bundles and configs.
Future<void> doctor({bool verbose = false}) async {
  final paths = dartToolPaths;
  final settings = await readSettings();
  stdout.writeln('default tool: ${settings.defaultToolOrDefault}');
  void bin(String title, String dir) {
    final index = paths.pathIndexOf(dir);
    stdout.writeln(
      '$title: $dir'
      '${index < 0 ? '  NOT on PATH' : '  on PATH (#$index)'}',
    );
  }

  bin('pub global bin', paths.pubCacheBinPath);
  bin('dart install bin', paths.dartInstallBinPath);
  final pubIndex = paths.pathIndexOf(paths.pubCacheBinPath);
  final installIndex = paths.pathIndexOf(paths.dartInstallBinPath);
  if (pubIndex >= 0 && installIndex >= 0) {
    stdout.writeln(
      pubIndex < installIndex
          ? 'a pub global binstub shadows a dart install executable of the '
                'same name'
          : 'a dart install executable shadows a pub global binstub of the '
                'same name',
    );
  }
  Set<String> executables(String dir) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      return {};
    }
    return directory
        .listSync()
        .map((entity) => p.basenameWithoutExtension(entity.path))
        .toSet();
  }

  final both = executables(
    paths.pubCacheBinPath,
  ).intersection(executables(paths.dartInstallBinPath));
  if (both.isNotEmpty) {
    final sorted = both.toList()..sort();
    stdout.writeln(
      'executables in both bin directories (${both.length}): '
      '${sorted.join(' ')}',
    );
  }
  final packages = await listGlobalToolPackages(
    includeInactive: true,
    verbose: verbose,
  );
  final byName = <String, List<GlobalToolPackage>>{};
  for (final package in packages) {
    byName.putIfAbsent(package.name, () => []).add(package);
  }
  final configured = (await listConfiguredPackages()).toSet();
  for (final entry in byName.entries) {
    final tools = entry.value.map((package) => package.tool).toSet();
    if (tools.length > 1) {
      stdout.writeln(
        'package ${entry.key} installed with both tools: '
        '${entry.value.join(', ')}',
      );
    }
  }
  final inactive = packages.where((package) => !package.active).toList();
  if (inactive.isNotEmpty) {
    stdout.writeln(
      'inactive dart install bundles (${inactive.length}, '
      '`dart uninstall <package>` then install again to reclaim): '
      '${inactive.join(', ')}',
    );
  }
  for (final name in byName.keys) {
    if (!configured.contains(name)) {
      final package = byName[name]!.first;
      if (package.source == 'git') {
        stdout.writeln(
          'package $name installed from git without a config: an update '
          'takes the default branch at the repository root',
        );
      }
    }
  }
  for (final name in configured) {
    if (!byName.containsKey(name)) {
      stdout.writeln(
        'config $name has no installed package (pubglobalupdate --install '
        '$name)',
      );
    }
  }
  stdout.writeln(
    '${packages.length} package(s): '
    '${packages.where((p) => p.tool == PubGlobalTool.activate).length} '
    'activated, '
    '${packages.where((p) => p.tool == PubGlobalTool.install && p.active).length} '
    'installed',
  );
}
