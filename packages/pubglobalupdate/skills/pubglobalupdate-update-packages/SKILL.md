---
name: pubglobalupdate-update-packages
description: >-
  Use when updating, refreshing, reinstalling or dry-running the global
  Dart/Flutter command line tools with the `pubglobalupdate` command: update
  every package installed with `dart pub global activate` or `dart install`
  (hosted, git or path) or only the packages named, install a missing one
  with `--install`, list them (`--list`), move one to the other tool
  (`--migrate`), check the setup (`--doctor`), or install and run
  pubglobalupdate itself.
---

# Update the global Dart tools

`pubglobalupdate` lists the packages of `dart pub global list` and
`dart installed` (Dart 3.10+), then runs again, for each one, the tool that
installed it (`dart pub global activate ...` or `dart install ...
--overwrite`) with the same source: hosted (latest version), git (same
url, path in the repository and ref) or path (same folder).

## Guidelines

- Install the tool once with `dart pub global activate pubglobalupdate` (or
  `flutter pub global activate pubglobalupdate`). The pub cache `bin`
  folder (`~/.pub-cache/bin`) must be on the `PATH` to find the
  `pubglobalupdate` executable, and `dart` must be on the `PATH` (it shells
  out to it).
- Run `pubglobalupdate` with no argument to update every package of both
  tools.
- Pass package names as positional arguments to restrict the update:
  `pubglobalupdate dhttpd webdev`. Unknown names are silently ignored.
  `--tool activate|install` restricts it to the packages of one tool.
- Use `--dry-run` (`-d`) to print the commands without running them. Prefer
  this first when unsure what will be touched.
- Use `--verbose` (`-v`) to see every command output and every version.
- Use `--install` with package names to install packages not installed
  yet: `pubglobalupdate --install my_tool` (saved config if any, hosted
  otherwise; the tool is `--tool`, else the config, else `--default-tool`,
  else `activate`). Without `--install` a package that is not installed is
  never installed.
- The source used, in priority order:
  1. the saved package config, if any (see the
     `pubglobalupdate-package-config` skill),
  2. the source reported by the tool: the hosted name, the git url (its
     path in the repository and ref are read from the tool's lock file:
     `<pub cache>/global_packages/<package>/pubspec.lock`, or the
     `dart install` app bundle), the local path,
  3. plain hosted install of the package name (`--install`).
- An update never moves a package from one tool to the other: when the
  config asks for the other tool it prints a `hint: ... --migrate` line.
  `pubglobalupdate --migrate <name>` moves it (uninstall, install with the
  other tool, config updated).
- A failing package (a path that no longer exists, a git repository gone,
  a resolution failure) is reported on stderr as `error: <package>: ...`
  and the others are still handled; the run ends with `failed: <packages>`
  on stderr and exit code 1. Exit code 0 means every package was updated.
- `--list [--all]` prints the packages of both tools with their source,
  `--doctor` checks the bin folders, the `PATH` order (a pub global binstub
  shadowing a `dart install` executable of the same name), packages in both
  tools, inactive bundles and configs without a package.
- Do not parse `pubglobalupdate` output programmatically; use the Dart API
  instead (`pubglobalupdate-dart-api` skill).
- Known limit: a package activated from a path holding a space is not read
  back correctly from `dart pub global list` (its update fails); a saved
  config for it fixes the source.

## Command reference

```
Usage: pubglobalupdate [<pkg1> <pkg2>...]

By default all packages are updated

Global options:
-h, --help                  Usage help
    --version               Display version
-v, --verbose               Verbose
    --config-package        Configure package source (using git url path and ref) and tool
    --config-read           Read package config (config-package options must be set)
    --config-clear          Clear package config (config-package options must be set)
    --config-list           List all package configuration and the settings
    --package-list          List all packages configured
    --install               Install package if not already activated/installed
    --source                Config source
                            [git, path, hosted]
    --git-url               Git url
    --git-path              Git path
    --git-ref               Git ref
    --path                  Path for path source
    --version-constraint    Config version constraint for a hosted source (^1.0.0)
-x, --executable            Config executable(s) to put on PATH (activate only)
    --hooks                 Config: the package needs build hooks, so dart install
    --tool                  The tool: activate (dart pub global activate) or install (dart install). Saved with --config-package, one-off otherwise
                            [activate, install]
    --default-tool          Save the tool used for packages without a configured tool
                            [activate, install]
    --list                  List the packages of both tools
    --all                   With --list: include inactive dart install bundles
    --migrate               Move package(s) to the other tool (or the one given by --tool or the config), keeping the config
    --doctor                Check the bin directories, PATH, duplicates and configs
-d, --dry-run               Do not run test, simple show the command executed
```

## Examples

Update everything:

```bash
pubglobalupdate
```

Preview what would run, without changing anything:

```bash
pubglobalupdate --dry-run
# dart pub global activate dhttpd
# dart pub global activate --source git https://github.com/tekartik/process_run.dart --git-path packages/process_run
# dart pub global activate --source path /home/me/dev/my_tool
# dart install "my_hook_tool@{path: /home/me/dev/my_hook_tool}" --overwrite
```

Update a single package, verbose:

```bash
pubglobalupdate -v dhttpd
```

Install a package that is not installed yet, using its saved config when
one exists, hosted otherwise:

```bash
pubglobalupdate --install dhttpd
pubglobalupdate --install --tool install my_tool
```

Move a package to `dart install` and check the result:

```bash
pubglobalupdate --migrate --tool install my_tool
pubglobalupdate --list
pubglobalupdate --doctor
```

Run from a clone of the repository without activating it:

```bash
dart run bin/pubglobalupdate.dart --dry-run
```

## Typical output

```
updating: dhttpd (activate)
updated: dhttpd 4.3.0
updating: my_tool (install)
updated: my_tool /home/me/.local/share/dart/install/bin/my_tool
updating: gone_tool (activate)
error: gone_tool: dart pub global activate --source path /home/me/old/gone_tool, exitCode 1, workingDirectory: .
The directory `/home/me/old/gone_tool` does not exist.
failed: gone_tool
```

An activated package prints an `updated:` line only when its version
changed (always with `-v`); a `dart install` package prints one each time.
`installing:`/`installed:` are used instead with `--install` and
`--migrate`.
