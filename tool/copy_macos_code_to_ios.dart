import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell();

  await shell.run('''
# Code is shared between ios and macos
# There is no easy way to do that so the macos code is the reference
# and is copied to ios
cp -R sqflite_sqlcipher/macos/sqflite_sqlcipher/Sources/ sqflite_sqlcipher/ios/sqflite_sqlcipher/Sources/

''');
}
