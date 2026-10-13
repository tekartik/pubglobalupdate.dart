/// `dart install` package argument (descriptor form) for a source.
///
/// - git: `name@{git: {url: <url>, ref: <ref>, path: <path>}}`
/// - path: `name@{path: <path>}`
/// - hosted: `name` or `name@<version>`
///
/// Not exported.
String dartInstallDescriptor(
  String package, {
  String? source,
  String? gitUrl,
  String? gitRef,
  String? gitPath,
  String? path,
  String? version,
}) {
  if (source == 'git') {
    final parts = [
      'url: $gitUrl',
      if (gitRef != null) 'ref: $gitRef',
      if (gitPath != null) 'path: $gitPath',
    ];
    return '$package@{git: {${parts.join(', ')}}}';
  } else if (source == 'path') {
    return '$package@{path: $path}';
  }
  return version == null ? package : '$package@$version';
}
