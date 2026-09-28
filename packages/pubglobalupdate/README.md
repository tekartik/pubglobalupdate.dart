# pubglobalupdate.dart

Command (Linux/Mac/Windows) to update all current global packages (git, path or hosted)
to their latest version, whether they were installed with `dart pub global activate`
or with `dart install` (Dart 3.10+, the one that supports build hooks).

[![Build Status](https://travis-ci.org/tekartik/pubglobalupdate.dart.svg)](https://travis-ci.org/tekartik/pubglobalupdate.dart)

## Activate

Choose one of the following two commands:

````
$ dart pub global activate pubglobalupdate
$ flutter pub global activate pubglobalupdate
````

## Usage

````
Usage: pubglobalupdate [<pkg1> <pkg2>...]

By default all packages are updated

Global options:
-h, --help       Usage help
    --version    Display version
-v, --verbose    Verbose
-d, --dry-run    Do not run test, simple show the command executed
````

Update all current activated packages

````
$ pubglobalupdate
````

Update one package

````
$ pubglobalupdate dhttpd
````

## dart install support

Each package can say which tool installs it, `activate` (`dart pub global activate`,
the default) or `install` (`dart install`):

````
# saved with the rest of the package config
$ pubglobalupdate --config-package my_tool --source git --git-url https://github.com/me/my_tool --tool install
# one-off
$ pubglobalupdate --install --tool install my_tool
# default for the packages without a configured tool
$ pubglobalupdate --default-tool install
# move an installed package to the other tool (config kept and updated)
$ pubglobalupdate --migrate my_tool
# what is installed with which tool, and a health check
$ pubglobalupdate --list
$ pubglobalupdate --doctor
````

The tool of an install is resolved in this order: `--tool`, the config, `hooks: true`
in the config (forces `install`), the default tool, `activate`. An update always runs
with the tool that owns the package and only prints a `--migrate` hint when the config
asks for the other one, so nothing is uninstalled without being asked.

## Dev

* before commit, run all unit tests
* to activate from your local drive: `dart pub global activate -s path .`
* to activate from git repository: `dart pub global activate -s git https://github.com/tekartik/pubglobalupdate.dart --git-path packages/pubglobalupdate`

### Dependencies

* [process_run](https://pub.dartlang.org/packages/process_run)
