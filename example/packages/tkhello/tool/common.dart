// Shared helpers of the experiment scripts (see README.md).
// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:tkhello/tkhello.dart';

const allPackages = ['tkhello', 'tkhellohooks'];

ToolOs get currentOs => Platform.isWindows
    ? ToolOs.windows
    : Platform.isMacOS
    ? ToolOs.macos
    : ToolOs.linux;

/// Common options of every script.
ArgParser experimentArgParser() => ArgParser()
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Usage help')
  ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Print outputs')
  ..addFlag(
    'isolated',
    negatable: false,
    help: 'Use temporary PUB_CACHE and DART_DATA_HOME under .local/isolated',
  )
  ..addOption('git-url', help: 'Git url of this repository, for the git rows')
  ..addOption('git-ref', help: 'Git ref (tag, branch, commit) for the git rows')
  ..addOption('report', help: 'Report file (markdown), default under .local');

/// One step: a command, its result, the JSON it printed if any.
class StepResult {
  StepResult({
    required this.title,
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });
  final String title;
  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;

  bool get ok => exitCode == 0;

  /// The JSON object printed by `--json`, found from the first line starting
  /// with `{` (pub prints resolution lines before it for path packages).
  Map<String, Object?>? get json {
    final lines = const LineSplitter().convert(stdout);
    final start = lines.indexWhere((line) => line.startsWith('{'));
    if (start < 0) {
      return null;
    }
    try {
      return jsonDecode(lines.sublist(start).join('\n'))
          as Map<String, Object?>;
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?>? get info => json?['info'] as Map<String, Object?>?;
  Map<String, Object?>? get extra => json?['extra'] as Map<String, Object?>?;
  String? get marker => json?['marker'] as String?;

  List<String> get outLines => const LineSplitter().convert(stdout);
  List<String> get errLines => const LineSplitter().convert(stderr);
}

/// Markdown report of one or more rows.
class Report {
  final _buffer = StringBuffer();
  final findings = <String>[];
  final verdicts = <(String, bool, String)>[];

  void h(int level, String text) => _buffer.writeln('\n${'#' * level} $text\n');
  void text(String text) => _buffer.writeln(text);

  void step(StepResult result, {int maxLines = 40}) {
    _buffer.writeln('\n#### ${result.title}\n');
    _buffer.writeln(
      '`${result.command}` → exit ${result.exitCode}, '
      '${result.duration.inMilliseconds} ms',
    );
    void block(String name, List<String> lines) {
      if (lines.isEmpty) {
        return;
      }
      _buffer.writeln('\n$name:\n```');
      for (final line in lines.take(maxLines)) {
        _buffer.writeln(line);
      }
      if (lines.length > maxLines) {
        _buffer.writeln('… (${lines.length - maxLines} more lines)');
      }
      _buffer.writeln('```');
    }

    final json = result.json;
    if (json != null) {
      // Keep the JSON out of the raw output, summarize it instead.
      final outLines = result.outLines;
      final start = outLines.indexWhere((line) => line.startsWith('{'));
      block('stdout (before json)', outLines.sublist(0, start));
      final info = result.info;
      _buffer.writeln('\njson: marker=${result.marker}, extra=${result.extra}');
      if (info != null) {
        for (final key in [
          'mode',
          'aot',
          'script',
          'executable',
          'resolvedExecutable',
          'executableArguments',
          'executableOnPath',
        ]) {
          _buffer.writeln('- $key: `${info[key]}`');
        }
      }
    } else {
      block('stdout', result.outLines);
    }
    block('stderr', result.errLines);
  }

  void finding(String text) {
    findings.add(text);
    _buffer.writeln('\n> **finding**: $text');
  }

  void verdict(String row, bool ok, String note) {
    verdicts.add((row, ok, note));
    _buffer.writeln('\n> **${ok ? 'PASS' : 'UNEXPECTED'}**: $row: $note');
  }

  @override
  String toString() => _buffer.toString();
}

/// One package, one tool environment (real or isolated), one report.
class Experiment {
  Experiment({
    required this.package,
    required this.report,
    this.isolated = false,
    this.verbose = false,
    this.gitUrl,
    this.gitRef,
  }) {
    final scriptPath = Platform.script.toFilePath();
    // tool/ of example/packages/tkhello
    repoRoot = p.normalize(
      p.join(p.dirname(scriptPath), '..', '..', '..', '..'),
    );
    env = Map<String, String>.from(Platform.environment);
    if (isolated) {
      env['PUB_CACHE'] = p.join(isolatedDir, 'pub-cache');
      env['DART_DATA_HOME'] = p.join(isolatedDir, 'dart-data-home');
    }
    paths = ToolPaths(os: currentOs, environment: env);
  }

  final String package;
  final Report report;
  final bool isolated;
  final bool verbose;
  final String? gitUrl;
  final String? gitRef;
  late final String repoRoot;
  late final Map<String, String> env;
  late final ToolPaths paths;

  String get isolatedDir => p.join(repoRoot, '.local', 'isolated');
  String get packageDir => p.join(repoRoot, 'example', 'packages', package);
  String get gitPath => 'example/packages/$package';
  bool get isWindows => Platform.isWindows;

  /// The executable name in a bin directory of the tools.
  String binName(String name) => isWindows ? '$name.bat' : name;

  String get pubGlobalBinstub =>
      p.join(paths.pubCacheBinPath, binName(package));
  String get dartInstallLink =>
      p.join(paths.dartInstallBinPath, binName(package));
  String get dartInstallBundleExe => p.join(
    paths.dartInstallAppBundlesPath,
    package,
    'local',
    'bundle',
    'bin',
    isWindows ? '$package.exe' : package,
  );
  String get markerFile => p.join(
    repoRoot,
    'example',
    'packages',
    'tkhello',
    'lib',
    'src',
    'marker.dart',
  );

  Future<StepResult> run(
    String title,
    String command, {
    String? workingDirectory,
  }) async {
    stdout.writeln('> $command');
    final shell = Shell(
      environment: env,
      includeParentEnvironment: false,
      workingDirectory: workingDirectory ?? repoRoot,
      throwOnError: false,
      verbose: verbose,
    );
    final watch = Stopwatch()..start();
    final results = await shell.run(command);
    final result = results.last;
    final step = StepResult(
      title: title,
      command: command,
      exitCode: result.exitCode,
      stdout: result.stdout as String,
      stderr: result.stderr as String,
      duration: watch.elapsed,
    );
    report.step(step);
    if (!step.ok && !verbose) {
      stdout.writeln(
        '  exit ${step.exitCode}: ${step.errLines.take(2).join(' | ')}',
      );
    }
    return step;
  }

  Future<StepResult> runExe(String title, String exe) => run(
    title,
    '${shellArgument(exe)} --json',
    workingDirectory: Directory.systemTemp.path,
  );

  /// Lines of a list command that mention the package.
  List<String> packageLines(StepResult result) =>
      result.outLines.where((line) => line.startsWith('$package ')).toList();

  /// Sets the build marker, returns the previous content.
  Future<String> setMarker(String marker) async {
    final file = File(markerFile);
    final previous = await file.readAsString();
    await file.writeAsString(
      previous.replaceFirst(
        RegExp("const buildMarker = '[^']*';"),
        "const buildMarker = '$marker';",
      ),
    );
    return previous;
  }

  Future<void> restoreMarker() async {
    await setMarker('m0');
  }

  bool get expectHooksFailure => package == 'tkhellohooks';

  void checkRun(String row, StepResult result, {required bool aot}) {
    final info = result.info;
    if (expectHooksFailure && !aot) {
      final failed =
          !result.ok && result.stderr.contains('No available native assets');
      report.verdict(
        row,
        failed,
        failed
            ? 'run fails as expected (no native assets), exit ${result.exitCode}'
            : 'expected the hooks failure, got exit ${result.exitCode} '
                  '(sqlite ${result.extra?['sqlite version']})',
      );
      return;
    }
    final ok = result.ok && info != null;
    final extra = result.extra ?? {};
    report.verdict(
      row,
      ok,
      ok
          ? 'runs, mode ${info['mode']}'
                '${extra.isEmpty ? '' : ', extra $extra'}'
          : 'exit ${result.exitCode}, no json',
    );
  }
}

/// Writes the report and prints the summary.
Future<void> finish(Report report, String reportPath) async {
  final file = File(reportPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(report.toString());
  stdout.writeln('\nReport: $reportPath');
  for (final (row, ok, note) in report.verdicts) {
    stdout.writeln('${ok ? 'PASS      ' : 'UNEXPECTED'} $row: $note');
  }
  for (final finding in report.findings) {
    stdout.writeln('finding: $finding');
  }
}

String defaultReportPath(Experiment experiment, String name) => p.join(
  experiment.repoRoot,
  '.local',
  '${name}_${Platform.operatingSystem}_$dartVersion.md',
);

/// Parses the common options, runs [body] for the package (first rest
/// argument, default tkhello).
Future<void> runScript(
  List<String> arguments,
  String name,
  Future<void> Function(Experiment experiment) body,
) async {
  final parser = experimentArgParser();
  final results = parser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run tool/$name.dart [tkhello|tkhellohooks]');
    stdout.writeln(parser.usage);
    return;
  }
  final package = results.rest.isEmpty ? 'tkhello' : results.rest.first;
  if (!allPackages.contains(package)) {
    stderr.writeln('Unknown package $package, expected one of $allPackages');
    exitCode = 64;
    return;
  }
  final report = Report();
  final experiment = Experiment(
    package: package,
    report: report,
    isolated: results.flag('isolated'),
    verbose: results.flag('verbose'),
    gitUrl: results.option('git-url'),
    gitRef: results.option('git-ref'),
  );
  report.h(
    1,
    '$name $package (${Platform.operatingSystem}, dart $dartVersion)',
  );
  report.text(
    'pub cache bin: `${experiment.paths.pubCacheBinPath}`, '
    'dart install bin: `${experiment.paths.dartInstallBinPath}`'
    '${experiment.isolated ? ' (isolated)' : ''}',
  );
  await body(experiment);
  await finish(
    report,
    results.option('report') ??
        defaultReportPath(experiment, '${name}_$package'),
  );
}
