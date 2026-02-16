import 'package:pub_semver/pub_semver.dart';

/// Update currently activated packages.
Future main(List<String> arguments) async =>
    throw UnimplementedError('Only supported for io applications');

/// Activate package according its saved configuration if any
Future<void> activatePackage(
  String packageName, {

  /// Set when updating
  Version? existingPackageVersion,
  bool? dryRun,
  bool? verbose,
}) async => throw UnimplementedError('Only supported for io applications');
