import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// Global config.
class GlobalPackageConfig {
  /// Source (git/hosted/path)
  final String? source;

  /// For source = 'hosted'
  final String? package; // for hosted
  /// For source = 'path'
  final String? path; // for path source
  /// For source = 'git'
  final String? gitPath;

  /// For source = 'git'
  final String? gitRef;

  /// For source = 'git'
  final String? gitUrl;

  /// Global config
  GlobalPackageConfig(
      {this.source,
      this.path,
      this.package,
      this.gitPath,
      this.gitRef,
      this.gitUrl});

  /// json encodable map.
  Map<String, Object?> toMap() {
    return {
      'source': source,
      if (path != null) 'path': path,
      if (package != null) 'package': package,
      if (gitPath != null) 'git-path': gitPath,
      if (gitRef != null) 'git-ref': gitRef,
      if (gitUrl != null) 'git-url': gitUrl,
    };
  }

  /// Global config from map
  factory GlobalPackageConfig.fromMap(Map map) {
    return GlobalPackageConfig(
      source: map['source'] as String?,
      path: map['path'] as String?,
      package: map['package'] as String?,
      gitPath: map['git-path'] as String?,
      gitRef: map['git-ref'] as String?,
      gitUrl: map['git-url'] as String?,
    );
  }

  /// Command line arg
  String toActivateArgsString() {
    var sb = StringBuffer();
    sb.write('--source $source');
    if (source == 'git') {
      sb.write(' $gitUrl');
      if (gitPath != null) {
        sb.write(' --git-path $gitPath');
      }
      if (gitRef != null) {
        sb.write(' --git-ref $gitRef');
      }
    } else if (source == 'path') {
      sb.write(' --path $path');
    } else if (source == 'hosted') {
      sb.write(' $package');
    } else {
      throw UnsupportedError('source $source');
    }
    return sb.toString();
  }
}

Directory get _configDir {
  var configDir =
      join(userAppDataPath, 'tekartik', 'pubglobalupdate', 'config');
  return Directory(configDir);
}

File _packageConfigFile(String package) {
  return File(join(_configDir.path, '$package.yaml'));
}

/// Write the config
Future<void> writeConfig(String package, GlobalPackageConfig config) async {
  await _configDir.create(recursive: true);
  var configFile = _packageConfigFile(package);
  await configFile.writeAsString(jsonEncode(config.toMap()));
}

/// Delete the config
Future<void> deleteConfig(String package) async {
  await _configDir.create(recursive: true);
  var configFile = _packageConfigFile(package);
  if (configFile.existsSync()) {
    await configFile.delete();
  }
}

/// Read the config
Future<GlobalPackageConfig?> readConfig(String package) async {
  var configFile = _packageConfigFile(package);
  if (!configFile.existsSync()) {
    return null;
  }
  var map = jsonDecode(await configFile.readAsString()) as Map;
  return GlobalPackageConfig.fromMap(map);
}
