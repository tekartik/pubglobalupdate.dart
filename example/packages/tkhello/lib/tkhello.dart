/// tkhello: a hello world CLI that tells how and from where it was launched.
///
/// Test subject of the `dart install` versus `dart pub global activate`
/// experiment, see the spec in `projects.dart/doc/ideas/cli_exp_spec.md`.
library;

export 'src/hello_app.dart' show runHelloApp;
export 'src/launch_info.dart' show LaunchInfo, LaunchMode, detectLaunchMode;
export 'src/marker.dart' show buildMarker;
export 'src/version.dart' show tkhelloVersion;
