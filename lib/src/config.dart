import 'dart:convert';
import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

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
  });

  /// Global config from map
  factory PubGlobalPackageConfig.fromMap(Map map) {
    return PubGlobalPackageConfig(
      source: map['source'] as String?,
      path: map['path'] as String?,
      package: map['package'] as String,
      gitPath: map['git-path'] as String?,
      gitRef: map['git-ref'] as String?,
      gitUrl: map['git-url'] as String?,
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

  /// json encodable map.
  Map<String, Object?> toMap() {
    return {
      'package': package,
      'source': ?source,
      'path': ?path,

      'git-path': ?gitPath,
      'git-ref': ?gitRef,
      'git-url': ?gitUrl,
    };
  }

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

  /// Command line arg
  String toActivateArgsString() {
    return shellArguments(toPubGlobalPackage().activateArgs);
  }
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
