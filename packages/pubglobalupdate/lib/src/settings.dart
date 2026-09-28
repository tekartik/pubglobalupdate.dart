import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:pubglobalupdate/src/config.dart';
import 'package:pubglobalupdate/src/tool.dart';

/// Global settings (not per package).
class PubGlobalSettings {
  /// Settings.
  PubGlobalSettings({this.defaultTool});

  /// From map.
  factory PubGlobalSettings.fromMap(Map<Object?, Object?> map) =>
      PubGlobalSettings(defaultTool: map['default-tool'] as String?);

  /// The tool for packages without a `tool` in their config
  /// (`activate` or `install`), null means `activate`.
  final String? defaultTool;

  /// The default tool, [PubGlobalTool.defaultTool] when not set.
  PubGlobalTool get defaultToolOrDefault =>
      PubGlobalTool.tryParse(defaultTool) ?? PubGlobalTool.defaultTool;

  /// json encodable map.
  Map<String, Object?> toMap() => {'default-tool': ?defaultTool};
}

/// The settings file, next to the package configs.
File get settingsFile =>
    File(join(dirname(packagesConfigDir.path), 'settings.yaml'));

/// Read the settings (empty when the file is missing or invalid).
Future<PubGlobalSettings> readSettings() async {
  final file = settingsFile;
  if (!file.existsSync()) {
    return PubGlobalSettings();
  }
  try {
    return PubGlobalSettings.fromMap(
      jsonDecode(await file.readAsString()) as Map,
    );
  } catch (e) {
    stderr.writeln('Error reading ${file.path}: $e');
    return PubGlobalSettings();
  }
}

/// Write the settings.
Future<void> writeSettings(PubGlobalSettings settings) async {
  final file = settingsFile;
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(settings.toMap()));
}
