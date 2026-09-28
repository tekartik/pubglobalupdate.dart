---
name: pubglobalupdate-package-config
description: >-
  Use when a globally activated Dart tool must track a git branch, a git
  sub directory or a local checkout with pubglobalupdate: save, read, list
  and clear a per-package activation source and tool (`--config-package`,
  `--source`, `--git-url`, `--git-ref`, `--git-path`, `--path`, `--tool`,
  `--config-list`, `--default-tool`), and where pubglobalupdate stores that
  configuration.
---

# Per-package activation config

`pubglobalupdate` can remember, per package, the exact
`dart pub global activate` source to use. A saved config always wins over
what `dart pub global list` reports.

## Guidelines

- Always pass `--config-package <name>` to any `--config-*` flag except
  `--config-list` and `--package-list`; the command exits with code 1
  otherwise.
- `--source` accepts `git`, `path` or `hosted`. Omitting it means `hosted`.
- With `--source git`, `--git-url` is required. `--git-ref` (branch, tag or
  commit) and `--git-path` (sub directory inside a mono repo) are optional.
- With `--source path`, `--path` is required. Prefer an absolute path: the
  value is stored verbatim and reused from any working directory.
- Save a config for every package activated with `--git-ref` or `--git-path`:
  `dart pub global list` only reports the git url, so without a config the
  next update re-activates the default branch at the repository root.
- Saving a config does not activate anything. Run
  `pubglobalupdate <name>` to update an already activated package, or
  `pubglobalupdate --install <name>` to activate it for the first time.
- Saving a config for a package overwrites any previous config for that
  package. Use `--config-read` to check the current one first.
- `--config-clear` removes the saved config; the next update falls back to
  the source reported by `dart pub global list`.
- `--config-list` prints every saved config as JSON, `--package-list` prints
  only the package names, one per line.
- Configs are stored one file per package, named `<package>.yaml`, in
  `<user app data>/tekartik/pubglobalupdate/config`. The content is JSON.
  `<user app data>` is `$APPDATA` on Windows and `~/.config` elsewhere, and
  can be overridden with the `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH` environment variable (the
  `userAppDataPath` value from `package:process_run`).
- Do not hand edit these files; use the command line flags or the Dart API
  (`writeConfig`, `readConfig`, `deleteConfig`, `listConfiguredPackages`
  from `package:pubglobalupdate/src/config.dart`).

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
  --git-ref main
pubglobalupdate --install process_run   # first activation
pubglobalupdate process_run             # later updates
```

Track a package inside a mono repo:

```bash
pubglobalupdate --config-package dev_build \
  --source git \
  --git-url https://github.com/tekartik/dev_build.dart \
  --git-path dev_build
```

Use a local checkout:

```bash
pubglobalupdate --config-package my_tool --source path --path /home/me/dev/my_tool
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
  "git-ref": "main",
  "git-url": "https://github.com/tekartik/process_run.dart"
}
```
