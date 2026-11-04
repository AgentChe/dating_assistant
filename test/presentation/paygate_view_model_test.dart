import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/service/purchase/model/purchase_error.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/model/store_product.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_store.dart';

class _FakePurchaseManager implements PurchaseManager {
  final products = [StoreProduct(fakeProduct('yearly', 59.99)), StoreProduct(fakeProduct('weekly', 7.99))];

  var result = PurchaseResult.subscribed;

  Object? error;

  final bought = <String>[];

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
  Future<PurchaseResult> restore() async => _result();

  PurchaseResult _result() {
    final error = this.error;
    if (error != null) throw error;
    return result;
  }
}

void main() {
  late _FakePurchaseManager purchaseManager;
  late PaygateViewModel viewModel;
  late List<PaygateAction> actions;

  setUp(() async {
    purchaseManager = _FakePurchaseManager();
    viewModel = PaygateViewModel(purchaseManager: purchaseManager, yearlyId: 'yearly', weeklyId: 'weekly');
    actions = [];
    viewModel.actions.listen(actions.add);
    await viewModel.loadProducts();
  });

  test('loads both plans and the yearly saving', () {
    expect(viewModel.hasProductsError, isFalse);
    expect(viewModel.selectedProduct?.id, 'yearly');
    expect(viewModel.yearlySavingPercent, 85);
    expect(viewModel.yearlyPricePerWeek, r'$1.15');
  });

  test('without product ids the plans fail to load', () async {
    final viewModel = PaygateViewModel(purchaseManager: purchaseManager, yearlyId: '', weeklyId: '');

    await viewModel.loadProducts();

    expect(viewModel.hasProductsError, isTrue);
    expect(viewModel.selectedProduct, isNull);
  });

  test('buys the selected plan and opens the welcome screen', () async {
    viewModel.selectPlan(PaygatePlan.weekly);

    await viewModel.purchase();
    await pumpEventQueue();

    expect(purchaseManager.bought, ['weekly']);
    expect(actions, [PaygateAction.subscribed]);
    expect(viewModel.isProcessing, isFalse);
  });

  test('a failed payment shows the failure and keeps the paygate', () async {
    purchaseManager.error = const PurchaseError(PurchaseErrorCode.paymentFailed);

    await viewModel.purchase();
    await pumpEventQueue();

    expect(viewModel.failure, PaygateFailure.paymentFailed);
    expect(actions, isEmpty);

    viewModel.selectPlan(PaygatePlan.weekly);
    expect(viewModel.failure, isNull);
  });

  test('restore without purchases says there is nothing to restore', () async {
    purchaseManager.result = PurchaseResult.notSubscribed;

    await viewModel.restore();

    expect(viewModel.failure, PaygateFailure.nothingToRestore);
  });

  test('a cancelled payment changes nothing', () async {
    purchaseManager.result = PurchaseResult.cancelled;

    await viewModel.purchase();
    await pumpEventQueue();

    expect(viewModel.failure, isNull);
    expect(actions, isEmpty);
  });
}
