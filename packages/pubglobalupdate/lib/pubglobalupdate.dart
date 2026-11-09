/// The `pubglobalupdate` command as a library (Dart VM only, a stub that
/// throws [UnimplementedError] elsewhere).
///
/// * [main]: the command line, `main(['--dry-run'])` as
///   `pubglobalupdate --dry-run`.
/// * [activatePackage]: `dart pub global activate` one package (saved config
///   first).
/// * [installPackage]: install one package with the resolved [PubGlobalTool].
/// * [migratePackage]: move one package to the other tool.
///
/// The functions for one package let the `ShellException` (process_run) of a
/// failing command through.
library;

export 'src/platform/pubglobalupdate.dart'
    show main, activatePackage, installPackage, migratePackage;
export 'src/tool.dart' show PubGlobalTool;
