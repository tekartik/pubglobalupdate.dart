import 'package:dev_build/shell.dart';

Future<void> main(List<String> args) async {
  await deactivatePubglobalUpdate();
}

/// Sage deactivate
Future<void> deactivatePubglobalUpdate() async {
  try {
    await run('dart pub global deactivate pubglobalupdate');
  } catch (_) {}
}
