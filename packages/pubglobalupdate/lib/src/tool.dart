/// The tool that installs a global package.
enum PubGlobalTool {
  /// `dart pub global activate`: JIT binstubs in the pub cache.
  activate('activate', 'dart pub global activate'),

  /// `dart install`: AOT app bundles, supports build hooks.
  install('install', 'dart install');

  const PubGlobalTool(this.name, this.command);

  /// Value on the command line and in the config (`activate`, `install`).
  final String name;

  /// The dart command it runs.
  final String command;

  /// The default when nothing is configured.
  static const PubGlobalTool defaultTool = activate;

  /// The names, for command line validation.
  static List<String> get names => values.map((tool) => tool.name).toList();

  /// Parses [name], null if null or unknown.
  static PubGlobalTool? tryParse(String? name) {
    for (final tool in values) {
      if (tool.name == name) {
        return tool;
      }
    }
    return null;
  }

  /// The other tool.
  PubGlobalTool get other => this == activate ? install : activate;

  @override
  String toString() => name;
}
