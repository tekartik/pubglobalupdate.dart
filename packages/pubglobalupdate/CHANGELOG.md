## 1.1.0

* `dart install` support (Dart 3.10+): packages installed with `dart install` are
  listed and updated (`dart install … --overwrite`) next to the activated ones
* Per package `tool` (`activate` or `install`) saved with `--config-package … --tool`,
  one-off with `--tool` on `--install`; `--default-tool` for the packages without one
  (resolution: command line, config, `hooks: true`, default, `activate`)
* `--install` honors the tool; `--migrate` moves a package to the other tool and
  saves it in the config; an update never moves a package, it prints the hint
* `--list [--all]` shows the packages of both tools, `--doctor` checks the bin
  directories, PATH order, duplicates, inactive bundles and configs
* Config gains `version` (hosted constraint, `--version-constraint`),
  `executables` (`-x`, activate only) and `hooks` (`--hooks`)
* Requires `process_run` 1.3.7 and `pub_semver`

## 1.0.5

* Moved to `packages/pubglobalupdate` in the repository (now a workspace). Activating
  from git needs `--git-path packages/pubglobalupdate`

## 1.0.4

* Add `pubglobalupdate-dart-api`, `pubglobalupdate-package-config` and `pubglobalupdate-update-packages` agent skills in `skills/`, installable with `dart run skills@ get`

## 1.0.3

* Requires dart 3.12

## 1.0.2+4

* Requires dart 3.11
* Add `--install` flag to force updating a configured package not installed yet

## 1.0.1+1

* Requires dart 3.7

## 1.0.0+1

* Make it 1.0.0
* Requires dart 3.5

## 0.5.4+2

* Allow saving a package config.
* Allow listing all packages configuration.

## 0.5.3

* Dart 3 support

## 0.5.2+1

* strict-cast and dart 2.18 support

## 0.5.1+1

* dart 2.14 lints

## 0.5.0

* nnbd support

## 0.4.3

* Dart 2.10 support without pub in the path

## 0.4.2+3

* Pedantic 1.9 support

## 0.4.0

* Dart2 support

## 0.3.3

* Add `implicit-cast: false` support

## 0.3.2

* Update dependencies to their latest version
* doc update

## 0.3.1

* Use process_run 0.5.0

## 0.3.0

* Initial version
