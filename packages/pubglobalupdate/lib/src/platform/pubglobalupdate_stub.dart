import 'package:dev_build/package.dart';
import 'package:pubglobalupdate/src/tool.dart';

/// Runs the `pubglobalupdate` command line with [arguments]: by default
/// updates every package of `dart pub global activate` and `dart install`.
///
/// A package that fails is reported on stderr and the others are still
/// handled, the exit code is then 1. Writes on stdout/stderr and may call
/// `exit(1)` on invalid options.
Future<void> main(List<String> arguments) async =>
    throw UnimplementedError('Only supported for io applications');

/// `dart pub global activate` [packageName] from its saved config, else from
/// [existingPackage] (a `dart pub global list` line read with
/// `PubGlobalPackage.fromListLine`), else hosted. [dryRun] prints the
/// command only.
Future<void> activatePackage(
  String packageName, {

  /// Set when updating
  bool? dryRun,
  bool? verbose,

  /// Resolved from command line
  PubGlobalPackage? existingPackage,
}) async => throw UnimplementedError('Only supported for io applications');

/// Installs [packageName] from its saved config (else hosted) with [tool],
/// else the config tool, else `install` when the config says `hooks`, else
/// the default tool (`--default-tool`), else `activate`.
Future<void> installPackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async => throw UnimplementedError('Only supported for io applications');

/// Moves the installed [packageName] to [tool] (else the config tool, else
/// the other tool): uninstalls it from its tool, installs it with the target
/// and saves the tool in its config.
Future<void> migratePackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async => throw UnimplementedError('Only supported for io applications');
