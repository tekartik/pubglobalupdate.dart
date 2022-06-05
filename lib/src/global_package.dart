library pubglobalupdate.global_package;

import 'package:pub_semver/pub_semver.dart';

/// Global package definition.
abstract class GlobalPackage {
  /// Package name.
  String? name;

  /// Package version.
  Version? version;

  /// `pub global activate` arguments
  List<String> get activateArgs;

  ///
  /// return null if it cannot be parsed
  ///
  static GlobalPackage? fromListLine(String line) {
    // split the line by spaces to get the arguments
    var parts = line.split(' ');

    GlobalPackage? package;
    String name;
    Version version;
    // pub.dartlang.org hosted package
    // ignore name
    if (parts.length >= 2) {
      // first is package name, last is path
      name = parts[0];
      try {
        version = Version.parse(parts[1]);
      } catch (_) {
        return null;
      }
    } else {
      // ignore
      return null;
    }

    //
    // hosted
    // pub.dartlang.org hosted package
    // ignore name
    if (parts.length == 2) {
      package = GlobalHostedPackage();
    } else if (parts.length >= 4) {
      //
      // handle git first
      //
      // tekartik_io_tools 0.7.1 from Git repository 'https://github.com/alextekartik/tekartik_io_tools.dart'
      // since 'from Git repository' might change, handle the 'git' word in the 2 words preceeding the source (last)
      bool isPartGit(int index) {
        return parts[index].toLowerCase() == 'git';
      }

      // look for git in the 2 arguments preceding the source
      if (isPartGit(parts.length - 2) || isPartGit(parts.length - 3)) {
        package = GlobalGitPackage();
      }

      if (package == null) {
        //
        // handle part
        //
        // tekartik_io_tools 0.7.1 at path '/media/ssd/devx/git/github.com/alextekartik/tekartik_io_tools.dart'
        // since 'at path' might change, handle the 'path' word  in the 2 words preceeding the source (last)
        bool isPartPath(int index) {
          return parts[index].toLowerCase() == 'path';
        }

        if (isPartPath(parts.length - 2) || isPartPath(parts.length - 3)) {
          package = GlobalPathPackage();
        }
      }

      // Git and path are source pacjage
      if (package is GlobalSourcePackage) {
        package.source = parts.last;
      }
    }

    if (package != null) {
      package.name = name;
      package.version = version;
    }
    return package;
  }

  /// Get global package from actived line.
  static GlobalPackage? fromActivatedLine(String line, String packageName) {
    final activated = 'activated';
    if (line.toLowerCase().startsWith(activated)) {
      final start = line.indexOf(packageName, activated.length);
      if (start != -1) {
        line = line.substring(start);
        // removing ending . if any
        if (line.endsWith('.')) {
          line = line.substring(0, line.length - 1);
        }
        final updatedPackage = GlobalPackage.fromListLine(line);
        return updatedPackage;
      }
    }
    return null;
  }

  @override
  String toString() => '$name $version';
}

/// pub.dartlang.org hosted package
class GlobalHostedPackage extends GlobalPackage {
  @override
  List<String> get activateArgs => [name!];
}

String _insetString(String source, [int offset = 1]) {
  return source.substring(offset, source.length - offset);
}

///
/// remove enclosing " or '
///
String _extractSource(String source) {
  if (source.startsWith('"') && source.endsWith('"')) {
    return _extractSource(_insetString(source));
  }
  if (source.startsWith("'") && source.endsWith("'")) {
    return _extractSource(_insetString(source));
  }
  return source;
}

/// Global package from source (git, path).
abstract class GlobalSourcePackage extends GlobalPackage {
  late String _source;

  /// Package source.
  String get source => _source;
  set source(String source) => _source = _extractSource(source);

  /// Source type (git, path)
  String get sourceType;

  @override
  List<String> get activateArgs => ['--source', sourceType, source];

  @override
  String toString() => '${super.toString()} $sourceType $source';
}

/// Global package from git.
class GlobalGitPackage extends GlobalSourcePackage {
  @override
  String get sourceType => 'git';
}

/// Global package from path.
class GlobalPathPackage extends GlobalSourcePackage {
  @override
  String get sourceType => 'path';
}
