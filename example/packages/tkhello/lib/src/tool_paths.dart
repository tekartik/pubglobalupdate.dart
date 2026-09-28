import 'package:path/path.dart' as p;

/// Operating system kind for the path rules.
enum ToolOs {
  /// Linux.
  linux,

  /// macOS.
  macos,

  /// Windows.
  windows,
}

/// Pure path rules of `dart pub global` and `dart install`, computed from an
/// environment map so they can be tested for every platform.
///
/// Sources: pub `system_cache.dart` for the pub cache, the `dart_data_home`
/// package for the Dart data home, dartdev `install/file_system.dart` for the
/// `install/bin` and `install/app-bundles` segments.
class ToolPaths {
  /// Rules for [os] with [environment].
  ToolPaths({required this.os, required Map<String, String> environment})
    : _env = environment;

  /// The operating system.
  final ToolOs os;
  final Map<String, String> _env;

  late final p.Context _ctx = p.Context(
    style: isWindows ? p.Style.windows : p.Style.posix,
  );

  /// True on Windows.
  bool get isWindows => os == ToolOs.windows;

  String? _envValue(String key) {
    if (isWindows) {
      // Environment keys are case insensitive on Windows.
      final upper = key.toUpperCase();
      for (final entry in _env.entries) {
        if (entry.key.toUpperCase() == upper) {
          return entry.value;
        }
      }
      return null;
    }
    return _env[key];
  }

  String _requireEnv(String key) =>
      _envValue(key) ?? (throw StateError('Missing environment variable $key'));

  /// The user home (`HOME`, or `USERPROFILE` on Windows).
  String get homePath =>
      _envValue('HOME') ??
      _envValue('USERPROFILE') ??
      (throw StateError('Missing HOME or USERPROFILE'));

  /// The pub cache: `PUB_CACHE`, else `%LOCALAPPDATA%\Pub\Cache` on Windows,
  /// else `~/.pub-cache`.
  String get pubCachePath {
    final override = _envValue('PUB_CACHE');
    if (override != null) {
      return override;
    }
    if (isWindows) {
      return _ctx.join(_requireEnv('LOCALAPPDATA'), 'Pub', 'Cache');
    }
    return _ctx.join(homePath, '.pub-cache');
  }

  /// Where `dart pub global activate` puts its binstubs.
  String get pubCacheBinPath => _ctx.join(pubCachePath, 'bin');

  /// The Dart data home: `DART_DATA_HOME`, else the OS state directory for
  /// `Dart` (`%LOCALAPPDATA%\Dart`, `~/Library/Application Support/Dart`,
  /// `$XDG_STATE_HOME/Dart` or `~/.local/state/Dart`).
  String get dartDataHomePath {
    final override = _envValue('DART_DATA_HOME');
    if (override != null) {
      return override;
    }
    switch (os) {
      case ToolOs.windows:
        return _ctx.join(_requireEnv('LOCALAPPDATA'), 'Dart');
      case ToolOs.macos:
        return _ctx.join(homePath, 'Library', 'Application Support', 'Dart');
      case ToolOs.linux:
        final stateHome =
            _envValue('XDG_STATE_HOME') ??
            _ctx.join(homePath, '.local', 'state');
        return _ctx.join(stateHome, 'Dart');
    }
  }

  /// The `dart install` directory.
  String get dartInstallPath => _ctx.join(dartDataHomePath, 'install');

  /// Where `dart install` puts its links (or `.bat` wrappers on Windows).
  String get dartInstallBinPath => _ctx.join(dartInstallPath, 'bin');

  /// Where `dart install` puts its app bundles.
  String get dartInstallAppBundlesPath =>
      _ctx.join(dartInstallPath, 'app-bundles');

  /// The `PATH` separator.
  String get pathSeparator => isWindows ? ';' : ':';

  /// The `PATH` entries, in order.
  List<String> get pathEntries => (_envValue('PATH') ?? '')
      .split(pathSeparator)
      .where((entry) => entry.isNotEmpty)
      .toList();

  String _normalize(String dir) {
    var normalized = _ctx.normalize(dir);
    if (isWindows) {
      normalized = normalized.toLowerCase();
    }
    return normalized;
  }

  /// Index of [dir] in `PATH`, -1 if absent.
  int pathIndexOf(String dir) {
    final normalized = _normalize(dir);
    final entries = pathEntries;
    for (var i = 0; i < entries.length; i++) {
      if (_normalize(entries[i]) == normalized) {
        return i;
      }
    }
    return -1;
  }

  /// True if [dir] is on `PATH`.
  bool isDirOnPath(String dir) => pathIndexOf(dir) >= 0;

  /// First match of [executable] on `PATH` (`.bat`, `.exe`, `.cmd` are tried
  /// first on Windows). [exists] tells whether a candidate path exists.
  String? findOnPath(
    String executable, {
    required bool Function(String path) exists,
  }) {
    final names = isWindows
        ? ['$executable.bat', '$executable.exe', '$executable.cmd', executable]
        : [executable];
    for (final dir in pathEntries) {
      for (final name in names) {
        final candidate = _ctx.join(dir, name);
        if (exists(candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }
}
