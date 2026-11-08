import 'dart:typed_data';

import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:hive_ce/hive_ce.dart';

var _boxes = 0;

/// Ящик Hive в памяти: на диск ничего не пишет, и тестам не нужен path_provider.
/// Имена у ящиков Hive общие на весь процесс, поэтому у каждого теста свой.
Future<Box<String>> memoryHistoryBox() => Hive.openBox<String>('history-test-${_boxes++}', bytes: Uint8List(0));

/// История на ящике в памяти.
Future<HistoryManager> memoryHistoryManager({HistoryMediator? mediator}) async =>
    HistoryManager(await memoryHistoryBox(), mediator ?? HistoryMediator());
