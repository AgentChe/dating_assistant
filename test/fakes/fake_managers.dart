import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/model/store_product.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:dating_assistant/service/session/model/subscription.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';

import 'fake_store.dart';

/// Покупки без магазина: годовой тариф за $59.99 и недельный за $7.99.
class FakePurchaseManager implements PurchaseManager {
  final products = [StoreProduct(fakeProduct('yearly', 59.99)), StoreProduct(fakeProduct('weekly', 7.99))];

  /// Чем закончатся покупка и восстановление.
  var result = PurchaseResult.subscribed;

  /// Если задана — покупка и восстановление бросают её.
  Object? error;

  final bought = <String>[];

  var restores = 0;

  @override
  void start() {}

  @override
  Future<List<StoreProduct>> obtainProducts(List<String> ids) async => [
    for (final id in ids) ...products.where((product) => product.id == id),
  ];

  @override
  Future<PurchaseResult> buy(StoreProduct product) async {
    bought.add(product.id);
    return _result();
  }

  @override
  Future<PurchaseResult> restore() async {
    restores++;
    return _result();
  }

  PurchaseResult _result() {
    final error = this.error;
    if (error != null) throw error;
    return result;
  }
}

/// Сессия без OtterScale: подписка задаётся в тесте.
class FakeSessionManager implements SessionManager {
  FakeSessionManager({this.subscription, bool? isPlus}) : isPlus = isPlus ?? subscription != null;

  bool isPlus;

  Subscription? subscription;

  @override
  bool get isEnabled => true;

  @override
  String? get anonymousId => 'anonymous-1';

  @override
  String? get internalId => null;

  @override
  Future<void> start({Duration timeout = const Duration(seconds: 5)}) async {}

  @override
  Future<void> refreshUserIds() async {}

  @override
  Future<bool> hasActiveSubscriptions() async => isPlus;

  @override
  Future<Subscription?> activeSubscription() async => isPlus ? subscription : null;
}

/// Счётчик генераций без сервера.
class FakeUsageManager implements UsageManager {
  FakeUsageManager({this.usage = const Usage(used: 0, limit: 3)});

  Usage usage;

  /// Если задана — запрос бросает её.
  Object? error;

  @override
  Future<Usage> obtainUsage() async {
    final error = this.error;
    if (error != null) throw error;
    return usage;
  }
}
