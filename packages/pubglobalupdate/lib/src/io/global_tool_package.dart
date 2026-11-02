import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:process_run/shell.dart';
import 'package:pubglobalupdate/src/dart_installed_package.dart';
import 'package:pubglobalupdate/src/install_descriptor.dart';
import 'package:pubglobalupdate/src/io/git_lock_source.dart';
import 'package:pubglobalupdate/src/tool.dart';

/// A package installed by one of the tools, from its list line.
class GlobalToolPackage {
  /// From a `dart pub global list` line.
  GlobalToolPackage.fromPubGlobal(PubGlobalPackage package, {this.gitLock})
    : tool = PubGlobalTool.activate,
      pubGlobal = package,
      installed = null;

  /// From a `dart installed` line.
  GlobalToolPackage.fromInstalled(DartInstalledPackage package, {this.gitLock})
    : tool = PubGlobalTool.install,
      pubGlobal = null,
      installed = package;

  /// The git source read from the lock file of the tool (git path and ref,
  /// not in the list lines), ignored when its url differs.
  final GitLockSource? gitLock;

  GitLockSource? get _gitLock {
    final gitLock = this.gitLock;
    final sourceValue = this.sourceValue;
    if (gitLock != null &&
        source == 'git' &&
        sourceValue != null &&
        isSameGitUrl(gitLock.url, sourceValue)) {
      return gitLock;
    }
    return null;
  }

  /// Path of a git package in its repository (from the lock file), null at
  /// its root or when unknown.
  String? get gitPath => _gitLock?.path;

  /// Requested git ref (from the lock file), null for the default branch or
  /// when unknown.
  String? get gitRef => _gitLock?.ref;

  /// The tool that owns it.
  final PubGlobalTool tool;

  /// The pub global line (tool activate).
  final PubGlobalPackage? pubGlobal;

  /// The dart installed line (tool install).
  final DartInstalledPackage? installed;

  /// Package name.
  String get name => pubGlobal?.name ?? installed!.name;

  /// Version.
  Version? get version => pubGlobal?.version ?? installed!.version;

  /// `hosted`, `git`, `path` (or `unknown`).
  String get source {
    final pubGlobal = this.pubGlobal;
    if (pubGlobal != null) {
      if (pubGlobal is PubGlobalGitPackage) {
        return 'git';
      } else if (pubGlobal is PubGlobalPathPackage) {
        return 'path';
      }
      return 'hosted';
    }
    return installed!.source;
  }

  /// The git url or the path.
  String? get sourceValue {
    final pubGlobal = this.pubGlobal;
    if (pubGlobal != null) {
      if (pubGlobal is PubGlobalGitPackage) {
        return pubGlobal.source;
      } else if (pubGlobal is PubGlobalPathPackage) {
        return pubGlobal.source;
      }
      return null;
    }
    return installed!.sourceValue;
  }

  /// False for a `dart install` bundle without executables on PATH.
  bool get active => installed?.active ?? true;

  /// Arguments to re-install with the same tool (an update).
  List<String> get updateArgs => argsFor(tool);

  /// Arguments to install with the other tool (a migration).
  List<String> get otherToolArgs => argsFor(tool.other);

  /// Arguments to install the same source with [tool].
  List<String> argsFor(PubGlobalTool tool) {
    final source = this.source;
    final sourceValue = this.sourceValue;
    if (tool == PubGlobalTool.activate) {
      if (source == 'git' && sourceValue != null) {
        return [
          '--source',
          'git',
          sourceValue,
          if (gitPath != null) ...['--git-path', gitPath!],
          if (gitRef != null) ...['--git-ref', gitRef!],
        ];
      } else if (source == 'path' && sourceValue != null) {
        return ['--source', 'path', sourceValue];
      }
      return [name];
    }
    return [
      dartInstallDescriptor(
        name,
        source: source,
        gitUrl: source == 'git' ? sourceValue : null,
        gitPath: source == 'git' ? gitPath : null,
        gitRef: source == 'git' ? gitRef : null,
        path: source == 'path' ? sourceValue : null,
      ),
    ];
  }

  @override
  String toString() =>
      '$name $version ($tool'
      '${source == 'hosted' ? '' : ', $source ${sourceValue ?? ''}'}'
      '${gitPath == null ? '' : ' path $gitPath'}'
      '${gitRef == null ? '' : ' ref $gitRef'}'
      '${active ? '' : ', not active'})';
}

/// Lists the packages of both tools (`dart pub global list`, then
/// `dart installed`, with `--all` when [includeInactive]).
///
/// Unparsable lines go to stderr. A dart without `dart installed` (before
/// 3.10) only yields the pub global packages.
Future<List<GlobalToolPackage>> listGlobalToolPackages({
  bool includeInactive = false,
  bool verbose = false,
}) async {
  final packages = <GlobalToolPackage>[];
  final list = await run('dart pub global list', verbose: verbose);
  for (final line in list.outLines) {
    final package = PubGlobalPackage.fromListLine(line);
    if (package == null) {
      stderr.writeln("Cannot parse package information '$line'");
    } else {
      packages.add(
        GlobalToolPackage.fromPubGlobal(
          package,
          gitLock: package is PubGlobalGitPackage
              ? readGitLockSource(pubGlobalLockPath(package.name), package.name)
              : null,
        ),
      );
    }
  }
  try {
    final installed = await run(
      'dart installed${includeInactive ? ' --all' : ''}',
      verbose: verbose,
    );
    for (final line in installed.outLines) {
      if (line.startsWith('No ') || line.trim().isEmpty) {
        // 'No Dart CLI tools installed.' and the --all hint
        continue;
      }
      final package = DartInstalledPackage.fromListLine(line);
      if (package == null) {
        stderr.writeln("Cannot parse installed package information '$line'");
      } else {
        final gitRef = package.gitRef;
        packages.add(
          GlobalToolPackage.fromInstalled(
            package,
            gitLock: gitRef != null
                ? readGitLockSource(
                    dartInstallGitLockPath(package.name, gitRef),
                    package.name,
                  )
                : null,
          ),
        );
      }
    }
  } on ShellException catch (e) {
    stderr.writeln(
      'dart installed failed (needs Dart 3.10 or later): ${e.message}',
    );
  }
  return packages;
}
