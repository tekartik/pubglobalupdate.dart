---
name: pubglobalupdate-update-packages
description: >-
  Use when updating, refreshing, reinstalling or dry-running globally
  activated Dart/Flutter command line tools with the `pubglobalupdate`
  command: update every `dart pub global activate`d package (hosted, git or
  path) to its latest version or only the packages named on the command line,
  install a missing one with `--install`, or install and run pubglobalupdate
  itself.
---

# Update globally activated packages

`pubglobalupdate` re-runs `dart pub global activate` for each package listed
by `dart pub global list`, keeping the original source (hosted, git or path).

## Guidelines

- Install the tool once with `dart pub global activate pubglobalupdate` (or
  `flutter pub global activate pubglobalupdate`). Make sure
  `~/.pub-cache/bin` is on the `PATH` so the `pubglobalupdate` executable is
  found.
- Run `pubglobalupdate` with no argument to update every activated package.
- Pass package names as positional arguments to restrict the update:
  `pubglobalupdate dhttpd process_run`. Unknown names are silently ignored.
- Use `--dry-run` (`-d`) to print the `dart pub global activate` commands
  without running them. Prefer this first when unsure what will be touched.
- Use `--verbose` (`-v`) to see every command output and every version, even
  when unchanged. Without it only `updated: <package> <version>` lines are
  printed for packages whose version changed.
- Use `--install` together with package names to activate packages that are
  not activated yet: `pubglobalupdate --install my_tool`. Without `--install`
  a package that is not in `dart pub global list` is never installed.
- The source used to reactivate is, in priority order:
  1. the saved package config, if any (see the
     `pubglobalupdate-package-config` skill),
  2. the source reported by `dart pub global list` (hosted version, git url
     and ref, or local path),
  3. plain hosted activation of the package name.
- Git and path activations are refreshed too: a path package is re-activated
  from the same directory, a git package is re-fetched from the same url.
  `dart pub global list` does not report `--git-ref`/`--git-path`, so a git
  package activated with those needs a saved config or it is re-activated
  from the default branch at the repository root.
- The tool shells out to `dart`, so `dart` must be on the `PATH`. Do not run
  it from a Flutter-only setup without a `dart` executable.
- Exit code is non zero when `dart pub global activate` fails for a package.
- Do not parse `pubglobalupdate` output programmatically; use the Dart API
  instead (`pubglobalupdate-dart-api` skill).

## Command reference

```
Usage: pubglobalupdate [<pkg1> <pkg2>...]

By default all packages are updated

Global options:
-h, --help              Usage help
    --version           Display version
-v, --verbose           Verbose
    --config-package    Configure package source (using git url path and ref)
    --config-read       Read package config (config-package options must be set)
    --config-clear      Clear package config (config-package options must be set)
    --config-list       List all package configuration
    --package-list      List all packages configured
    --install           Install package if not already activated
    --source            Config source [git, path, hosted]
    --git-url           Git url
    --git-path          Git path
    --git-ref           Git ref
    --path              Path for path source
-d, --dry-run           Do not run test, simple show the command executed
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
# dart pub global activate -s git https://github.com/tekartik/process_run.dart
# dart pub global activate -s path /home/me/dev/my_tool
```

Update a single package, verbose:

```bash
pubglobalupdate -v dhttpd
```

Install a package that is not activated yet, using its saved config when one
exists, hosted otherwise:

```bash
pubglobalupdate --install dhttpd
```

Run from a clone of the repository without activating it:

```bash
dart run bin/pubglobalupdate.dart --dry-run
```

## Typical output

```
updating: dhttpd
updated: dhttpd 4.3.0
updating: process_run
```

Only packages whose version changed print an `updated:` line unless `-v` is
set. `installing:`/`installed:` are used instead when the package was not
activated before (`--install`).
