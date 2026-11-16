import 'dart:convert';

import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/service/usage/usage_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_managers.dart';
import '../fakes/fake_usage.dart';

/// Keychain в памяти: в тестах нативной части плагина нет.
class _FakeKeychain extends Fake implements FlutterSecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => value == null ? values.remove(key) : values[key] = value;
}

void main() {
  late MemoryUsageStorage storage;
  late FakeSessionManager session;
  late UsageMediator mediator;
  late int changes;
  late DateTime now;

  UsageManager manager() => UsageManager(storage, session, mediator, now: () => now);

  setUp(() {
    storage = MemoryUsageStorage();
    session = FakeSessionManager(isPlus: false);
    mediator = UsageMediator();
    changes = 0;
    mediator.changes.listen((_) => changes++);
    // Среда: неделя началась в понедельник, 9 ноября.
    now = DateTime(2026, 11, 11, 22);
  });

  test('a new user has all three free generations', () async {
    final usage = await manager().obtainUsage();

    expect((usage.used, usage.limit, usage.left), (0, 3, 3));
  });

  test('counts generations on the device and stops at the weekly limit', () async {
    final usage = manager();
    for (var index = 0; index < UsageManager.freePerWeek; index++) {
      await usage.checkLimit();
      await usage.recordGeneration();
    }
    await pumpEventQueue();

    expect((await usage.obtainUsage()).left, 0);
    final error = await usage.checkLimit().then<Object?>((_) => null, onError: (Object error) => error);
    expect(error, isA<GenerationLimitReached>());
    expect(UsageManager.isGenerationLimit(error!), isTrue);
    // Профиль и экраны узнают о каждой потраченной генерации.
    expect(changes, 3);
    // Счётчик переживает перезапуск: новый менеджер читает то же хранилище.
    expect((await manager().obtainUsage()).used, 3);
  });

  test('a new week starts on Monday from zero', () async {
    storage.value = jsonEncode({'week': '2026-11-09', 'used': 3});

    now = DateTime(2026, 11, 15, 23, 59);
    expect((await manager().obtainUsage()).left, 0, reason: 'Sunday is still the same week');

    now = DateTime(2026, 11, 16, 0, 1);
    expect((await manager().obtainUsage()).left, 3, reason: 'Monday starts a new one');
  });

  test('with Cue Plus there is no limit and nothing is counted', () async {
    storage.value = jsonEncode({'week': '2026-11-09', 'used': 3});
    session.isPlus = true;
    final usage = manager();

    await usage.checkLimit();
    await usage.recordGeneration();
    await pumpEventQueue();

    expect((await usage.obtainUsage()).used, 3);
    expect(changes, 0);
  });

  test('a counter that cannot be read starts the week over', () async {
    storage.value = 'not json';

    expect((await manager().obtainUsage()).used, 0);
  });

  test('on iOS the counter lives in the Keychain, on Android in the preferences', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final keychain = _FakeKeychain();
    final device = DeviceUsageStorage(preferences, keychain: keychain);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await device.write('ios');
    expect(keychain.values.values, ['ios']);
    expect(await device.read(), 'ios');

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await device.read(), isNull);
    await device.write('android');
    expect(await device.read(), 'android');
    expect(keychain.values.values, ['ios']);
  });
}
