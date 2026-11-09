---
name: pubglobalupdate-package-config
description: >-
  Use when a global Dart tool (dart pub global activate or dart install)
  must track a git branch, a git sub directory, a local checkout, a version
  constraint or a given tool with pubglobalupdate: save, read, list and
  clear a per-package source and tool (`--config-package`, `--source`,
  `--git-url`, `--git-ref`, `--git-path`, `--path`, `--version-constraint`,
  `--executable`, `--hooks`, `--tool`, `--config-list`, `--default-tool`),
  and where pubglobalupdate stores that configuration.
---

# Per-package activation config

`pubglobalupdate` can remember, per package, the exact source and tool to
use (`dart pub global activate` or `dart install`). A saved config always
wins over what `dart pub global list` and `dart installed` report.

## Guidelines

- Always pass `--config-package <name>` to any `--config-*` flag except
  `--config-list` and `--package-list`; the command exits with code 1
  otherwise.
- `--source` accepts `git`, `path` or `hosted`. Omitting it means `hosted`.
- With `--source git`, `--git-url` is required. `--git-ref` (branch, tag or
  commit) and `--git-path` (sub directory inside a mono repo) are optional.
- With `--source path`, `--path` is required. Prefer an absolute path: the
  value is stored verbatim and reused from any working directory.
- Without a config, a git package keeps its `--git-path` and `--git-ref`
  (read from the lock file of the tool since 1.1.2). Save a config to pin
  them anyway, for a package not installed yet (`--install`), or for a
  path holding a space (not read back correctly from `dart pub global
  list`).
- `--tool activate|install` saves the tool; `--hooks` says the package
  needs build hooks (forces `dart install`); `--version-constraint ^1.2.0`
  (hosted) and `-x <executable>` (activate only, repeatable) are passed to
  the tool.
- Saving a config does not install anything. Run
  `pubglobalupdate <name>` to update an installed package, or
  `pubglobalupdate --install <name>` to install it for the first time.
  An update keeps the tool that owns the package and only prints a
  `--migrate` hint when the config asks for the other one.
- Saving a config for a package overwrites any previous config for that
  package. Use `--config-read` to check the current one first.
- `--config-clear` removes the saved config; the next update falls back to
  the source reported by the tool.
- `--config-list` prints the settings (`default-tool`) and every saved
  config as JSON, `--package-list` prints only the package names, one per
  line. `--default-tool install` saves the tool used for packages without a
  configured one (in `settings.yaml`, next to the `config` folder).
- Configs are stored one file per package, named `<package>.yaml`, in
  `<user app data>/tekartik/pubglobalupdate/config`. The content is JSON.
  `<user app data>` is `$APPDATA` on Windows and `~/.config` elsewhere, and
  can be overridden with the `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH` environment variable (the
  `userAppDataPath` value from `package:process_run`).
- Prefer the command line flags. A hand written yaml config is read too
  (an unreadable one is reported on stderr and ignored); `settings.yaml` is
  read as JSON only. `src/config.dart` is not public API.

## Saved config keys

| Key        | Meaning                                    | Sources     |
| ---------- | ------------------------------------------ | ----------- |
| `package`  | Package name (always present)              | all         |
| `source`   | `git`, `path` or `hosted` (absent = hosted)| all         |
| `git-url`  | Repository url                             | git         |
| `git-ref`  | Branch, tag or commit                      | git         |
| `git-path` | Sub directory in the repository            | git         |
| `path`     | Local directory of the package             | path        |
| `tool`     | `activate` or `install` (`--tool`)         | all         |
| `version`  | Hosted constraint (`--version-constraint`) | hosted      |
| `executables` | Executables on PATH (`-x`, activate only) | all      |
| `hooks`    | `true` forces `dart install` (`--hooks`)   | all         |

## Examples

Track a git branch of a tool:

```bash
pubglobalupdate --config-package process_run \
  --source git \
  --git-url https://github.com/tekartik/process_run.dart \
  --git-path packages/process_run \
  --git-ref master
pubglobalupdate --install process_run   # first activation
pubglobalupdate process_run             # later updates
```

Track a package inside a mono repo:

```bash
pubglobalupdate --config-package dev_build \
  --source git \
  --git-url https://github.com/tekartik/dev_test.dart \
  --git-path dev_build
```

Use a local checkout:

```bash
pubglobalupdate --config-package my_tool --source path --path /home/me/dev/my_tool
```

Install with `dart install` (build hooks), then update:

```bash
pubglobalupdate --config-package my_hook_tool --source path \
  --path /home/me/dev/my_hook_tool --hooks
pubglobalupdate --install my_hook_tool   # dart install
pubglobalupdate my_hook_tool
```

Force hosted (pub.dev) even if currently activated from git:

```bash
pubglobalupdate --config-package dhttpd --source hosted
```

Inspect and remove:

```bash
pubglobalupdate --config-package process_run --config-read
pubglobalupdate --config-list
pubglobalupdate --package-list
pubglobalupdate --config-package process_run --config-clear
```

Output of `--config-read` for the git example above:

```json
{
  "package": "process_run",
  "source": "git",
  "git-path": "packages/process_run",
  "git-ref": "master",
  "git-url": "https://github.com/tekartik/process_run.dart"
}
```
