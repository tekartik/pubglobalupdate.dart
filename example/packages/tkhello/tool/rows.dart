// The four rows of the matrix: {pub global, dart install} × {path, git}.
// ignore_for_file: public_member_api_docs
import 'dart:io';

import 'package:process_run/shell.dart';

import 'common.dart';

Future<void> pubGlobalPathRow(Experiment x) async {
  final r = x.report;
  final row = 'pub global / path / ${x.package}';
  r.h(2, row);
  final activate =
      'dart pub global activate -s path ${shellArgument(x.packageDir)} --overwrite';
  await x.run('activate', activate);
  final list = await x.run('list', 'dart pub global list');
  r.finding('pub global list line: `${x.packageLines(list).join(' | ')}`');
  final binstub = await x.runExe('run binstub', x.pubGlobalBinstub);
  x.checkRun('$row: binstub', binstub, aot: false);
  // `pub global run <pkg>:<name>` wants the script name (bin/<name>.dart),
  // not the executable name of the `executables:` section (verified: exit 66
  // "Could not find bin/tkhello.dart in package tkhello").
  final byExeName = await x.run(
    'run via dart pub global run <pkg>:<executable name> (expected to fail)',
    'dart pub global run ${x.package}:${x.package} --json',
    workingDirectory: Directory.systemTemp.path,
  );
  r.finding(
    '`dart pub global run ${x.package}:${x.package}` (executable name): exit '
    '${byExeName.exitCode} `${byExeName.errLines.take(1).join()}`',
  );
  final globalRun = await x.run(
    'run via dart pub global run <pkg>:main (script name)',
    'dart pub global run ${x.package}:main --json',
    workingDirectory: Directory.systemTemp.path,
  );
  x.checkRun('$row: pub global run', globalRun, aot: false);
  await x.run('update (re-activate, unchanged)', activate);
  await x.setMarker('m1');
  try {
    final rerun = await x.runExe(
      'run after a local edit, no re-activate',
      x.pubGlobalBinstub,
    );
    r.finding(
      'path package edited (marker m1), binstub without re-activate sees marker '
      '`${rerun.marker}`',
    );
    await x.run('update (re-activate after the edit)', activate);
    final updated = await x.runExe('run after re-activate', x.pubGlobalBinstub);
    r.finding('after re-activate the binstub sees marker `${updated.marker}`');
  } finally {
    await x.restoreMarker();
  }
  await x.run('deactivate', 'dart pub global deactivate ${x.package}');
  final after = await x.run('list after deactivate', 'dart pub global list');
  r.finding(
    'after deactivate, list lines: `${x.packageLines(after).join(' | ')}` '
    '(binstub exists: ${File(x.pubGlobalBinstub).existsSync()})',
  );
}

Future<void> installPathRow(Experiment x) async {
  final r = x.report;
  final row = 'dart install / path / ${x.package}';
  r.h(2, row);
  final install = 'dart install ${shellArgument(x.packageDir)}';
  final first = await x.run('install', install);
  r.finding('install output: `${first.outLines.join(' | ')}`');
  final installed = await x.run('installed', 'dart installed');
  r.finding('dart installed line: `${x.packageLines(installed).join(' | ')}`');
  final all = await x.run('installed --all', 'dart installed --all');
  r.finding('dart installed --all lines: `${x.packageLines(all).join(' | ')}`');
  final link = await x.runExe('run link in install/bin', x.dartInstallLink);
  x.checkRun('$row: link', link, aot: true);
  final bundle = await x.runExe(
    'run bundle executable',
    x.dartInstallBundleExe,
  );
  x.checkRun('$row: bundle exe', bundle, aot: true);
  final again = await x.run('update (re-install, unchanged)', install);
  r.finding(
    'unchanged re-install: ${again.duration.inMilliseconds} ms, output '
    '`${again.outLines.join(' | ')}`',
  );
  await x.setMarker('m1');
  try {
    final stale = await x.runExe(
      'run after a local edit, no re-install',
      x.dartInstallLink,
    );
    r.finding(
      'edited (marker m1), installed link without re-install sees `${stale.marker}`',
    );
    await x.run('update (re-install after the edit)', install);
    final updated = await x.runExe('run after re-install', x.dartInstallLink);
    r.finding('after re-install the link sees marker `${updated.marker}`');
  } finally {
    await x.restoreMarker();
  }
  await x.run('uninstall', 'dart uninstall ${x.package}');
  final after = await x.run(
    'installed --all after uninstall',
    'dart installed --all',
  );
  r.finding(
    'after uninstall, lines: `${x.packageLines(after).join(' | ')}`, '
    'link exists: ${File(x.dartInstallLink).existsSync()}, bundle dir exists: '
    '${Directory(x.dartInstallBundleExe).parent.parent.parent.existsSync()}',
  );
}

bool _requireGit(Experiment x) {
  if (x.gitUrl == null) {
    x.report.text('skipped: no --git-url');
    stdout.writeln('skipped: no --git-url');
    return false;
  }
  return true;
}

Future<void> pubGlobalGitRow(Experiment x) async {
  final r = x.report;
  final row = 'pub global / git / ${x.package}';
  r.h(2, row);
  if (!_requireGit(x)) {
    return;
  }
  final ref = x.gitRef == null ? '' : ' --git-ref ${shellArgument(x.gitRef!)}';
  final activate =
      'dart pub global activate -s git ${shellArgument(x.gitUrl!)}$ref '
      '--git-path ${x.gitPath} --overwrite';
  await x.run('activate', activate);
  final list = await x.run('list', 'dart pub global list');
  r.finding(
    'pub global list line (git): `${x.packageLines(list).join(' | ')}`',
  );
  final binstub = await x.runExe('run binstub', x.pubGlobalBinstub);
  x.checkRun('$row: binstub', binstub, aot: false);
  await x.run('update (re-activate)', activate);
  await x.run('deactivate', 'dart pub global deactivate ${x.package}');
}

Future<void> installGitRow(Experiment x) async {
  final r = x.report;
  final row = 'dart install / git / ${x.package}';
  r.h(2, row);
  if (!_requireGit(x)) {
    return;
  }
  final ref = x.gitRef == null ? '' : ', ref: ${x.gitRef}';
  final descriptor =
      '${x.package}@{git: {url: ${x.gitUrl}$ref, path: ${x.gitPath}}}';
  final install = 'dart install ${shellArgument(descriptor)}';
  final first = await x.run('install (descriptor form)', install);
  r.finding('git install output: `${first.outLines.join(' | ')}`');
  final installed = await x.run('installed', 'dart installed');
  r.finding(
    'dart installed line (git): `${x.packageLines(installed).join(' | ')}`',
  );
  final link = await x.runExe('run link in install/bin', x.dartInstallLink);
  x.checkRun('$row: link', link, aot: true);
  await x.run('update (re-install)', install);
  final refOpt = x.gitRef == null
      ? ''
      : ' --git-ref ${shellArgument(x.gitRef!)}';
  final old = await x.run(
    'install (old url form, may be refused)',
    'dart install ${shellArgument(x.gitUrl!)} --git-path ${x.gitPath}$refOpt --overwrite',
  );
  r.finding('old `<url> --git-path` form: exit ${old.exitCode}');
  await x.run('uninstall', 'dart uninstall ${x.package}');
}
