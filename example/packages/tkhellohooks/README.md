# tkhellohooks

`tkhello` plus the sqlite version, read through `sqflite_common_ffi`. Its `sqlite3`
dependency has a build hook, so this is the hooks case of the experiment: it
activates with `dart pub global activate` but fails at run time, and works with
`dart install` (spec: `projects.dart/doc/ideas/cli_exp_spec.md`). Not published.

```
$ tkhellohooks
Hello from tkhellohooks!
sqlite version: 3.51.0
```

The scripts live in `../tkhello/tool`, run them with the package name:
`dart run tool/install_path.dart tkhellohooks`.
