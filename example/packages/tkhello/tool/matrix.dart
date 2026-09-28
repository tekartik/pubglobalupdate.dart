// Runs every row on every package and writes one report.
import 'dart:io';

import 'package:process_run/shell.dart';

import 'common.dart';
import 'rows.dart';

Future<void> main(List<String> arguments) async {
  final parser = experimentArgParser()
    ..addOption(
      'packages',
      help: 'Comma separated packages',
      defaultsTo: allPackages.join(','),
    );
  final results = parser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run tool/matrix.dart [options]');
    stdout.writeln(parser.usage);
    return;
  }
  final report = Report();
  report.h(1, 'matrix (${Platform.operatingSystem}, dart $dartVersion)');
  Experiment? last;
  for (final package in results.option('packages')!.split(',')) {
    final x = Experiment(
      package: package.trim(),
      report: report,
      isolated: results.flag('isolated'),
      verbose: results.flag('verbose'),
      gitUrl: results.option('git-url'),
      gitRef: results.option('git-ref'),
    );
    last = x;
    report.text(
      '\npub cache bin: `${x.paths.pubCacheBinPath}`, '
      'dart install bin: `${x.paths.dartInstallBinPath}`'
      '${x.isolated ? ' (isolated)' : ''}',
    );
    await pubGlobalPathRow(x);
    await installPathRow(x);
    await pubGlobalGitRow(x);
    await installGitRow(x);
  }
  await finish(
    report,
    results.option('report') ?? defaultReportPath(last!, 'matrix'),
  );
}
