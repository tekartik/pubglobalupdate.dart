# pubglobalupdate

A command (Linux, macOS, Windows) that updates all your global Dart tools at
once, whether they were installed with `dart pub global activate` or with
`dart install` (Dart 3.10+, the one that supports build hooks), keeping
their source: hosted (pub.dev), git or a local path.

[![pub package](https://img.shields.io/pub/v/pubglobalupdate.svg)](https://pub.dev/packages/pubglobalupdate)

## Getting started

```sh
dart pub global activate pubglobalupdate

pubglobalupdate             # update every package of both tools
pubglobalupdate dhttpd      # only the packages named
pubglobalupdate --dry-run   # print the commands, run nothing
```

It needs `dart` on the `PATH`, and the pub cache `bin` folder
(`~/.pub-cache/bin`, `%LOCALAPPDATA%\Pub\Cache\bin` on Windows) on the
`PATH` to find `pubglobalupdate` itself. `flutter pub global activate
pubglobalupdate` works too.

## What an update does

It lists the packages with `dart pub global list` and `dart installed`, then
runs again, for each one, the tool that installed it with the same source:

* hosted: the latest version (or the configured constraint);
* git: the same url, path in the repository and ref (read from the lock file
  of the tool, or from the saved config);
* path: the same folder.

Each package prints an `updating:` line; an `updated:` line follows for a
`dart install` package, and for an activated one when its version changed
(always with `-v`). A package that fails (a deleted folder, a repository gone)
is reported on stderr (`error: <package>: ...`) and the others are still
updated; the run then ends with `failed: <packages>` and exit code 1.

## Commands

| Command | Does |
|---|---|
| `pubglobalupdate [<pkg>...]` | update all (or the named) packages |
| `--dry-run`, `-d` | print the commands only |
| `--verbose`, `-v` | show the commands output and every version |
| `--install <pkg>...` | install packages not installed yet (saved config, else hosted) |
| `--list [--all]` | the packages of both tools (`--all`: inactive `dart install` bundles too) |
| `--migrate <pkg>...` | move packages to the other tool (or `--tool`), the config is updated |
| `--doctor` | check the bin folders, the `PATH` order, duplicates and configs |
| `--config-package <pkg> ...` | save the source and tool of a package (see below) |
| `--config-read`, `--config-clear` | with `--config-package`: show or delete its config |
| `--config-list`, `--package-list` | all saved configs (and the settings), or their names |
| `--default-tool activate\|install` | the tool for packages without a configured one |

Run `pubglobalupdate --help` for every option.

## Saved config

A saved config wins over what the tools report. Use it for a package that
must come from a git branch, a sub folder of a repository, a local
checkout, or a given tool:

```sh
# git, sub folder and branch
pubglobalupdate --config-package process_run --source git \
  --git-url https://github.com/tekartik/process_run.dart \
  --git-path packages/process_run --git-ref master
# a local checkout, installed with dart install
pubglobalupdate --config-package my_tool --source path --path /home/me/dev/my_tool --tool install
# then install it once, later updates use it too
pubglobalupdate --install my_tool
```

Other config options: `--version-constraint` (hosted), `-x`/`--executable`
(executables put on the `PATH`, activate only), `--hooks` (the package needs
build hooks: `dart install`). The configs are json files in
`~/.config/tekartik/pubglobalupdate/config/<package>.yaml`
(`%APPDATA%\tekartik\...` on Windows, or under
`$TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH`).

The tool of an install is, in this order: `--tool`, the config, `hooks:
true` in the config (forces `install`), `--default-tool`, `activate`. An
update always uses the tool that owns the package; when the config asks for
the other one it only prints a `--migrate` hint, nothing is uninstalled
without being asked.

## Dart API

`package:pubglobalupdate/pubglobalupdate.dart` (Dart VM only) exports
`main` (the command line), `activatePackage`, `installPackage`,
`migratePackage` and `PubGlobalTool`:

```dart
import 'package:pubglobalupdate/pubglobalupdate.dart';

Future<void> main() async {
  // Prints: dart pub global activate dhttpd
  await activatePackage('dhttpd', dryRun: true);
}
```

These functions let the `ShellException` of a failing command through
(only the command line `main` goes on with the next package).

## Common mistakes

* A package that is not installed yet is ignored by an update: use
  `--install`. Unknown names are ignored silently.
* Expecting an update to move a package from `dart pub global activate` to
  `dart install` (or back): use `--migrate`.
* A package activated from a path holding a space (`dart pub global
  activate --source path "/my dir/tool"`) is not read back correctly from
  `dart pub global list` and its update fails: save a config for it
  (`--config-package <name> --source path --path "/my dir/tool"`), the
  config wins.
* Running the same activation from two tools at once (an update while a
  `run_ci` activates webdev): `dart pub global activate` may fail (exit
  66), run it again.

## Development

* Before commit, run the unit tests: `dart test`.
* Activate from a local checkout: `dart pub global activate -s path .`
* Activate from git: `dart pub global activate -s git
  https://github.com/tekartik/pubglobalupdate.dart --git-path
  packages/pubglobalupdate`
