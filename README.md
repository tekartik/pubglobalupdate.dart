# pubglobalupdate.dart

Command (Linux/Mac/Windows) to update all current global activated packages (git, path or hosted) 
to their latest version

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

## Dev

* before commit, run all unit tests
* to activate from your local drive: `dart pub global activate -s path .`
* to activate from git repository: `dart pub global activate -s git https://github.com/tekartik/pubglobalupdate.dart`

### Dependencies

* [process_run](https://pub.dartlang.org/packages/process_run)
