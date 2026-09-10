---
name: pubglobalupdate-dart-api
description: >-
  Use when writing a Dart script or tool that updates or activates global
  pub packages programmatically with `package:pubglobalupdate` (`main`,
  `activatePackage`) and `PubGlobalPackage` from `package:dev_build`, or when
  pubglobalupdate appears in a pubspec dependencies section.
---

# pubglobalupdate Dart API

The package is first a command line tool; its library surface is small and
VM only (`dart:io`).

## Guidelines

- Add it to `dependencies` (not `dev_dependencies`) when the code that calls
  it is a runnable script, for example under `tool/`:

  ```yaml
  dependencies:
    pubglobalupdate: ^1.0.3
  ```

- Import only the public library:

  ```dart
  import 'package:pubglobalupdate/pubglobalupdate.dart';
  ```

  It exports exactly two functions: `main` and `activatePackage`. Everything
  under `lib/src/` is private API and may change without a major version
  bump.
- `Future<void> main(List<String> arguments)` runs the full command line
  behaviour. Pass the same arguments you would pass on the shell. It writes to
  `stdout`/`stderr` and may call `exit(1)` on invalid `--config-*` usage, so do
  not call it from code that must keep running after an error.
- `Future<void> activatePackage(String packageName, {bool? dryRun, bool? verbose, PubGlobalPackage? existingPackage})`
  activates one package:
  - a saved config for `packageName` is used first,
  - otherwise `existingPackage` (a `PubGlobalPackage` from
    `package:dev_build/package.dart`) provides the source and current version,
  - otherwise `dart pub global activate <packageName>` (hosted) is run.
  - `dryRun: true` only prints the command.
- To obtain `existingPackage`, run `dart pub global list` with
  `package:process_run` and parse each line with
  `PubGlobalPackage.fromListLine(line)`; it returns `null` for lines it cannot
  parse.
- `activatePackage` never throws for an unknown package; it lets
  `dart pub global activate` fail and the `ShellException` from
  `package:process_run` propagate. Catch `ShellException` if you need to
  continue with the next package.
- Only import on the Dart VM. The library resolves to a stub on the web that
  throws `UnimplementedError`.
- Do not depend on the printed `updated:` lines from library code; compare
  `PubGlobalPackage.version` before and after instead.

## Examples

Forward the command line from your own executable:

```dart
import 'package:pubglobalupdate/pubglobalupdate.dart' as pubglobalupdate;

Future<void> main(List<String> arguments) => pubglobalupdate.main(arguments);
```

Update a fixed list of tools from a `tool/` script:

```dart
import 'package:dev_build/package.dart';
import 'package:process_run/shell_run.dart';
import 'package:pubglobalupdate/pubglobalupdate.dart';

Future<void> main() async {
  const wanted = {'dhttpd', 'process_run'};

  var result = await run('dart pub global list', verbose: false);
  var activated = <String, PubGlobalPackage>{};
  for (var line in result.outLines) {
    var package = PubGlobalPackage.fromListLine(line);
    if (package != null) {
      activated[package.name] = package;
    }
  }

  for (var name in wanted) {
    try {
      // Installs when missing, updates otherwise.
      await activatePackage(name, existingPackage: activated[name]);
    } on ShellException catch (e) {
      print('failed to activate $name: ${e.message}');
    }
  }
}
```

Preview the commands only:

```dart
await activatePackage('dhttpd', dryRun: true);
// prints: dart pub global activate dhttpd
```
