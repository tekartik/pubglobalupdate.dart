import 'package:dev_build/package.dart';
import 'package:pubglobalupdate/src/tool.dart';

/// Update currently activated packages.
Future<void> main(List<String> arguments) async =>
    throw UnimplementedError('Only supported for io applications');

/// Activate package according its saved configuration if any
Future<void> activatePackage(
  String packageName, {

  /// Set when updating
  bool? dryRun,
  bool? verbose,

  /// Resolved from command line
  PubGlobalPackage? existingPackage,
}) async => throw UnimplementedError('Only supported for io applications');

/// Install package with a tool
Future<void> installPackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async => throw UnimplementedError('Only supported for io applications');

/// Move a package to the other tool
Future<void> migratePackage(
  String packageName, {
  PubGlobalTool? tool,
  bool? dryRun,
  bool? verbose,
}) async => throw UnimplementedError('Only supported for io applications');
