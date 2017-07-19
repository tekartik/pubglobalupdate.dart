library pubglobalupdate.global_package;

import 'package:pub_semver/pub_semver.dart';

abstract class GlobalPackage {
  String name;
  Version version;

  List<String> get activateArgs;

  ///
  /// return null if it cannot be parsed
  ///
  static GlobalPackage fromListLine(String line) {
    // split the line by spaces to get the arguments
    var parts = line.split(" ");

    GlobalPackage package;
    String name;
    Version version;
    // pub.dartlang.org hosted package
    // ignore name
    if (parts.length >= 2) {
      // first is package name, last is path
      name = parts[0];
      try {
        version = new Version.parse(parts[1]);
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
      package = new GlobalHostedPackage();
    } else if (parts.length >= 4) {
      //
      // handle git first
      //
      // tekartik_io_tools 0.7.1 from Git repository "https://github.com/alextekartik/tekartik_io_tools.dart"
      // since 'from Git repository' might change, handle the 'git' word in the 2 words preceeding the source (last)
      bool _isPartGit(int index) {
        return parts[index].toLowerCase() == 'git';
      }

      // look for git in the 2 arguments preceding the source
      if (_isPartGit(parts.length - 2) || _isPartGit(parts.length - 3)) {
        package = new GlobalGitPackage();
      }

      if (package == null) {
        //
        // handle part
        //
        // tekartik_io_tools 0.7.1 at path "/media/ssd/devx/git/github.com/alextekartik/tekartik_io_tools.dart"
        // since 'at path' might change, handle the 'path' word  in the 2 words preceeding the source (last)
        bool _isPartPath(int index) {
          return parts[index].toLowerCase() == 'path';
        }

        if (_isPartPath(parts.length - 2) || _isPartPath(parts.length - 3)) {
          package = new GlobalPathPackage();
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

  static GlobalPackage fromActivatedLine(String line, String packageName) {
    String activated = "activated";
    if (line.toLowerCase().startsWith(activated)) {
      int start = line.indexOf(packageName, activated.length);
      if (start != -1) {
        line = line.substring(start);
        // removing ending . if any
        if (line.endsWith('.')) {
          line = line.substring(0, line.length - 1);
        }
        GlobalPackage updatedPackage = GlobalPackage.fromListLine(line);
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
  GlobalHostedPackage();

  List<String> get activateArgs => [name];
}

_insetString(String source, [int offset = 1]) {
  return source.substring(offset, source.length - offset);
}

///
/// remove enclosing " or '
///
_extractSource(String source) {
  if (source.startsWith('"') && source.endsWith('"')) {
    return _extractSource(_insetString(source));
  }
  if (source.startsWith("'") && source.endsWith("'")) {
    return _extractSource(_insetString(source));
  }
  return source;
}

abstract class GlobalSourcePackage extends GlobalPackage {
  String _source;
  String get source => _source;
  set source(String source) => _source = _extractSource(source);
  String get sourceType;

  List<String> get activateArgs => ['--source', sourceType, source];

  @override
  String toString() => '${super.toString()} $sourceType $source';
}

class GlobalGitPackage extends GlobalSourcePackage {
  String get sourceType => 'git';
}

class GlobalPathPackage extends GlobalSourcePackage {
  String get sourceType => 'path';
}
