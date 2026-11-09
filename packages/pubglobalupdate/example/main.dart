// The command line in your own executable: forwards the arguments to
// pubglobalupdate, `dart run example/main.dart --dry-run` prints the update
// commands of every global package (dart pub global activate and dart
// install) without running them.
import 'dart:async';

import 'package:pubglobalupdate/pubglobalupdate.dart' as pubglobalupdate;

Future<void> main(List<String> arguments) => pubglobalupdate.main(arguments);
