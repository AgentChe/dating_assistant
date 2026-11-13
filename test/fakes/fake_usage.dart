import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/service/usage/usage_storage.dart';

import 'fake_managers.dart';

/// Счётчик генераций в памяти — вместо Keychain и настроек.
class MemoryUsageStorage implements UsageStorage {
  MemoryUsageStorage([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

/// Настоящий UsageManager со счётчиком в памяти; по умолчанию у пользователя нет Cue Plus.
UsageManager memoryUsageManager({
  UsageStorage? storage,
  SessionManager? sessionManager,
  UsageMediator? usageMediator,
  DateTime Function()? now,
}) => UsageManager(
  storage ?? MemoryUsageStorage(),
  sessionManager ?? FakeSessionManager(isPlus: false),
  usageMediator ?? UsageMediator(),
  now: now,
);
