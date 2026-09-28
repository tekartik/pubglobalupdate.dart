# tkhello

Hello world CLI that tells how and from where it was installed and launched.
Test subject of the `dart install` versus `dart pub global activate` experiment
(spec: `projects.dart/doc/ideas/cli_exp_spec.md`). Not published: install it from
this git repository or from a path.

```
$ tkhello
Hello from tkhello!
$ tkhello --info      # launch mode, Platform values, bin directories, PATH verdicts
$ tkhello --json      # the same as one JSON object, for the tool scripts
```

## Install

```
# path
dart pub global activate -s path example/packages/tkhello
dart install example/packages/tkhello
# git
dart pub global activate -s git https://github.com/tekartik/pubglobalupdate.dart --git-path example/packages/tkhello
dart install 'tkhello@{git: {url: https://github.com/tekartik/pubglobalupdate.dart, path: example/packages/tkhello}}'
```

## Experiment scripts (`tool/`)

Each script takes the package name (`tkhello` or `tkhellohooks`) and runs
install → list → run → update → uninstall with one tool and one source, printing
what it observes. `matrix.dart` runs them all and writes a report under `.local/`.
`clean.dart` removes every trace of both packages from both tools.
`example/hosted_process_run.dart` is the manual hosted example (a real public
package, run by hand only).
