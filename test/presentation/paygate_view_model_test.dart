import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/service/purchase/model/purchase_error.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_managers.dart';

void main() {
  late FakePurchaseManager purchaseManager;
  late PaygateViewModel viewModel;
  late List<PaygateAction> actions;

  setUp(() async {
    purchaseManager = FakePurchaseManager();
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
