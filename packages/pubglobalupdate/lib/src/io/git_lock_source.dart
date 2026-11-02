import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:yaml/yaml.dart';

/// The git source of a package as resolved in a `pubspec.lock`.
///
/// Neither `dart pub global list` nor `dart installed` prints the path of a
/// git package in its repository, both tools keep it in a lock file:
/// - `dart pub global activate`: `<pub cache>/global_packages/<package>/pubspec.lock`
/// - `dart install`: `<app bundles>/<package>/git/<resolved ref>/pubspec.lock`
class GitLockSource {
  /// A git source.
  GitLockSource({required this.url, this.path, this.ref});

  /// Git url.
  final String url;

  /// Path of the package in the repository, null at its root.
  final String? path;

  /// Requested ref (branch, tag...), null for the default branch (`HEAD`).
  final String? ref;

  @override
  String toString() =>
      '$url${path == null ? '' : ' path $path'}${ref == null ? '' : ' ref $ref'}';
}

/// True if [url1] and [url2] are the same git url, `dart pub global list`
/// prints a `file://` url as a path.
bool isSameGitUrl(String url1, String url2) {
  String normalize(String url) {
    if (url.startsWith('file:')) {
      try {
        return Uri.parse(url).toFilePath();
      } catch (_) {}
    }
    return url;
  }

  return url1 == url2 || normalize(url1) == normalize(url2);
}

/// The git source of [package] in a `pubspec.lock` [content], null if it is
/// not a git package there (or the content cannot be read).
GitLockSource? parseGitLockSource(String content, String package) {
  try {
    final packages = (loadYaml(content) as Map)['packages'] as Map;
    final entry = packages[package] as Map?;
    if (entry == null || entry['source'] != 'git') {
      return null;
    }
    final description = entry['description'] as Map;
    final path = description['path'] as String?;
    final ref = description['ref'] as String?;
    return GitLockSource(
      url: description['url'] as String,
      path: (path == null || path.isEmpty || path == '.') ? null : path,
      ref: (ref == null || ref.isEmpty || ref == 'HEAD') ? null : ref,
    );
  } catch (_) {
    return null;
  }
}

/// The lock file of a package activated with `dart pub global activate`.
String pubGlobalLockPath(String package) =>
    join(pubCachePath, 'global_packages', package, 'pubspec.lock');

/// The lock file of a git package installed with `dart install`, resolved at
/// [gitRef] (the short ref printed by `dart installed`), null if not found.
String? dartInstallGitLockPath(String package, String gitRef) {
  if (gitRef.isEmpty) {
    return null;
  }
  final dir = Directory(
    join(dartToolPaths.dartInstallAppBundlesPath, package, 'git'),
  );
  try {
    for (final entity in dir.listSync()) {
      if (entity is Directory && basename(entity.path).startsWith(gitRef)) {
        return join(entity.path, 'pubspec.lock');
      }
    }
  } catch (_) {}
  return null;
}

/// The git source of [package] in the lock file at [lockPath], null if not
/// found.
GitLockSource? readGitLockSource(String? lockPath, String package) {
  if (lockPath == null) {
    return null;
  }
  try {
    final file = File(lockPath);
    if (!file.existsSync()) {
      return null;
    }
    return parseGitLockSource(file.readAsStringSync(), package);
  } catch (_) {
    return null;
  }
}
