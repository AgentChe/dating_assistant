import 'package:dating_assistant/misc/app.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PurchaseManager.registerStore();
  await Injector.configure();
  // Магазин может прислать покупку в любой момент — слушаем его с самого старта.
  Injector.shared.purchaseManager.start();
  runApp(const App());
}
