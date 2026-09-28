import 'common.dart';
import 'rows.dart';

Future<void> main(List<String> arguments) =>
    runScript(arguments, 'pub_global_path', pubGlobalPathRow);
