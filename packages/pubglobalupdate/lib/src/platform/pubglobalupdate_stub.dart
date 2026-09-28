import 'package:dev_build/package.dart';

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
