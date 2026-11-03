import 'package:dating_assistant/misc/app.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injector.configure();
  runApp(const App());
}
