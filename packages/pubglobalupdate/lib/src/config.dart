import 'dart:convert';
import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pubglobalupdate/src/tool.dart';

/// Global config.
class PubGlobalPackageConfig {
  /// Global config
  PubGlobalPackageConfig({
    this.source,
    this.path,
    required this.package,
    this.gitPath,
    this.gitRef,
    this.gitUrl,
    this.tool,
    this.version,
    this.executables,
    this.hooks,
  });

  /// Global config from map
  factory PubGlobalPackageConfig.fromMap(Map<Object?, Object?> map) {
    return PubGlobalPackageConfig(
      source: map['source'] as String?,
      path: map['path'] as String?,
      package: map['package'] as String,
      gitPath: map['git-path'] as String?,
      gitRef: map['git-ref'] as String?,
      gitUrl: map['git-url'] as String?,
      tool: map['tool'] as String?,
      version: map['version'] as String?,
      executables: (map['executables'] as List?)?.cast<String>(),
      hooks: map['hooks'] as bool?,
    );
  }

  /// Source (git/hosted/path), null means hosted
  final String? source;

  /// For all source
  final String package; // for hosted
  /// For source = 'path'
  final String? path; // for path source
  /// For source = 'git'
  final String? gitPath;

  /// For source = 'git'
  final String? gitRef;

  /// For source = 'git'
  final String? gitUrl;

  /// The tool: `activate` (dart pub global activate) or `install`
  /// (dart install), null means not configured.
  final String? tool;

  /// Version constraint (hosted source), for example `^1.3.0`.
  final String? version;

  /// Executables to put on PATH (`dart pub global activate --executable`),
  /// ignored by `dart install` which has no equivalent.
  final List<String>? executables;

  /// True when the package needs build hooks, which forces `dart install`.
  final bool? hooks;

  /// The configured tool, null when not configured or unknown.
  PubGlobalTool? get toolOrNull => PubGlobalTool.tryParse(tool);

  /// True for the hosted source (default).
  bool get isHosted => source == 'hosted' || source == null;

  /// json encodable map.
  Map<String, Object?> toMap() {
    return {
      'package': package,
      'source': ?source,
      'path': ?path,

      'git-path': ?gitPath,
      'git-ref': ?gitRef,
      'git-url': ?gitUrl,
      'tool': ?tool,
      'version': ?version,
      'executables': ?executables,
      'hooks': ?hooks,
    };
  }

  /// A copy with [tool] (and optionally [hooks]) changed.
  PubGlobalPackageConfig copyWith({String? tool, bool? hooks}) =>
      PubGlobalPackageConfig(
        package: package,
        source: source,
        path: path,
        gitPath: gitPath,
        gitRef: gitRef,
        gitUrl: gitUrl,
        tool: tool ?? this.tool,
        version: version,
        executables: executables,
        hooks: hooks ?? this.hooks,
      );

  /// To a package ready to install
  PubGlobalPackage toPubGlobalPackage() {
    var sourceType = source;
    var package = this.package;
    if (sourceType == 'git') {
      return PubGlobalGitPackageInstall(
        package,
        gitUrl: gitUrl!,
        gitRef: gitRef,
        gitPath: gitPath,
      );
    } else if (sourceType == 'path') {
      return PubGlobalPathPackageInstall(package, path: path!);
    } else if (sourceType == 'hosted' || sourceType == null) {
      return PubGlobalHostedPackageInstall(package);
    } else {
      throw ArgumentError('Unknown source type: $sourceType');
    }
  }

  /// `dart pub global activate` arguments.
  List<String> get activateArgs => [
    ...toPubGlobalPackage().activateArgs,
    if (isHosted && version != null) version!,
    for (final executable in executables ?? const <String>[]) ...[
      '--executable',
      executable,
    ],
  ];

  /// `dart pub global activate` arguments as a command line string.
  String toActivateArgsString() => shellArguments(activateArgs);

  /// `dart install` arguments (descriptor form).
  List<String> get installArgs {
    if (source == 'git') {
      final parts = [
        'url: $gitUrl',
        if (gitRef != null) 'ref: $gitRef',
        if (gitPath != null) 'path: $gitPath',
      ];
      return ['$package@{git: {${parts.join(', ')}}}'];
    } else if (source == 'path') {
      return ['$package@{path: $path}'];
    }
    return [if (version == null) package else '$package@$version'];
  }

  /// `dart install` arguments as a command line string.
  String toInstallArgsString() => shellArguments(installArgs);
}

@internal
/// Package config directory
Directory get packagesConfigDir {
  var configDir = join(
    userAppDataPath,
    'tekartik',
    'pubglobalupdate',
    'config',
  );

  return Directory(configDir);
}

File _packageConfigFile(String package) {
  return File(join(packagesConfigDir.path, '$package.yaml'));
}

/// Write the config
Future<void> writeConfig(String package, PubGlobalPackageConfig config) async {
  await packagesConfigDir.create(recursive: true);
  var configFile = _packageConfigFile(package);
  await configFile.writeAsString(jsonEncode(config.toMap()));
}

/// Delete the config
Future<void> deleteConfig(String package) async {
  await packagesConfigDir.create(recursive: true);
  var configFile = _packageConfigFile(package);
  if (configFile.existsSync()) {
    await configFile.delete();
  }
}

/// List all configured packages.
Future<List<String>> listConfiguredPackages() async {
  var list = await Directory(packagesConfigDir.path)
      .list()
      .where(
        (entity) =>
            FileSystemEntity.isFileSync(entity.path) &&
            extension(entity.path) == '.yaml',
      )
      .map((entity) => basenameWithoutExtension(entity.path))
      .toList();
  return list;
}

/// Read the config
Future<PubGlobalPackageConfig?> readConfig(String package) async {
  var configFile = _packageConfigFile(package);
  if (!configFile.existsSync()) {
    return null;
  }
  var map = jsonDecode(await configFile.readAsString()) as Map;
  try {
    return PubGlobalPackageConfig.fromMap(map);
  } catch (e) {
    // ignore: avoid_print
    print('Error reading config for $package: $e');
    return null;
  }
}
