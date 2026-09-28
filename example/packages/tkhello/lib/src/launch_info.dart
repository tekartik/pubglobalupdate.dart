import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

/// How the executable was launched.
enum LaunchMode {
  /// `dart pub global activate` binstub running the JIT snapshot under
  /// `global_packages`.
  pubGlobalBinstub('pub global binstub (JIT snapshot under global_packages)'),

  /// A JIT snapshot under `.dart_tool/pub/bin`: `dart run :exe`, or
  /// `dart pub global run` of a path package.
  jitSnapshot('JIT snapshot under .dart_tool/pub/bin'),

  /// `dart run bin/x.dart` or `dart bin/x.dart`.
  dartScript('dart run <script>.dart'),

  /// `dart install` AOT app bundle.
  dartInstall('dart install (AOT app bundle)'),

  /// Another AOT executable (`dart build cli`, `dart compile exe`).
  aotExecutable('AOT executable (dart build cli or dart compile exe)');

  const LaunchMode(this.description);

  /// Human description.
  final String description;
}

/// Pure detection from the `Platform` values (paths, any separator).
LaunchMode detectLaunchMode({
  required String script,
  required String executable,
  required String resolvedExecutable,
}) {
  final normalized = script.replaceAll('\\', '/');
  if (normalized.endsWith('.snapshot')) {
    return normalized.contains('/global_packages/')
        ? LaunchMode.pubGlobalBinstub
        : LaunchMode.jitSnapshot;
  }
  if (normalized.endsWith('.dart')) {
    return LaunchMode.dartScript;
  }
  // AOT: `Platform.script` is the link in `install/bin` (verified on Linux),
  // only `Platform.resolvedExecutable` shows the app bundle.
  final resolved = resolvedExecutable.replaceAll('\\', '/');
  if (normalized.contains('/app-bundles/') ||
      resolved.contains('/app-bundles/')) {
    return LaunchMode.dartInstall;
  }
  return LaunchMode.aotExecutable;
}

String _scriptPath(Uri script) {
  if (script.scheme == 'file') {
    return script.toFilePath();
  }
  return script.toString();
}

/// Launch diagnostics of the running executable.
class LaunchInfo {
  /// Diagnostics of the current process, [executableName] being the name the
  /// tools put on `PATH`.
  LaunchInfo.current({required this.executableName, DartToolPaths? toolPaths})
    : script = _scriptPath(Platform.script),
      executable = Platform.executable,
      resolvedExecutable = Platform.resolvedExecutable,
      executableArguments = Platform.executableArguments,
      dartVersion = Platform.version,
      paths = toolPaths ?? dartToolPaths {
    mode = detectLaunchMode(
      script: script,
      executable: executable,
      resolvedExecutable: resolvedExecutable,
    );
  }

  /// The executable name on `PATH`.
  final String executableName;

  /// `Platform.script` as a path.
  final String script;

  /// `Platform.executable`.
  final String executable;

  /// `Platform.resolvedExecutable`.
  final String resolvedExecutable;

  /// `Platform.executableArguments`.
  final List<String> executableArguments;

  /// `Platform.version`.
  final String dartVersion;

  /// The path rules used (process_run `DartToolPaths`).
  final DartToolPaths paths;

  /// The detected launch mode.
  late final LaunchMode mode;

  /// True for an AOT launch.
  bool get isAot =>
      mode == LaunchMode.dartInstall || mode == LaunchMode.aotExecutable;

  /// The first `PATH` match of [executableName], if any (process_run
  /// `whichSync` on the environment of [paths]).
  String? get executableOnPath => whichSync(
    executableName,
    environment: paths.environment,
    includeParentEnvironment: false,
  );

  String _onPath(String dir) {
    final index = paths.pathIndexOf(dir);
    return index < 0 ? 'no' : 'yes (#$index)';
  }

  /// JSON encodable map.
  Map<String, Object?> toMap() => {
    'mode': mode.name,
    'aot': isAot,
    'script': script,
    'executable': executable,
    'resolvedExecutable': resolvedExecutable,
    'executableArguments': executableArguments,
    'dartVersion': dartVersion,
    'pubCacheBin': paths.pubCacheBinPath,
    'pubCacheBinPathIndex': paths.pathIndexOf(paths.pubCacheBinPath),
    'dartInstallBin': paths.dartInstallBinPath,
    'dartInstallBinPathIndex': paths.pathIndexOf(paths.dartInstallBinPath),
    'executableOnPath': executableOnPath,
    'scriptDir': p.dirname(script),
  };

  /// Text lines.
  List<String> toLines() => [
    'launched: ${mode.description}${isAot ? ' [aot]' : ' [jit]'}',
    'script: $script',
    'executable: $executable',
    'resolved executable: $resolvedExecutable',
    'executable arguments: $executableArguments',
    'dart: $dartVersion',
    'pub cache bin: ${paths.pubCacheBinPath}  on PATH: ${_onPath(paths.pubCacheBinPath)}',
    'dart install bin: ${paths.dartInstallBinPath}  on PATH: ${_onPath(paths.dartInstallBinPath)}',
    '$executableName on PATH: ${executableOnPath ?? 'not found'}',
  ];
}
