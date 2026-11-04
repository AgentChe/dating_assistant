import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/model/store_product.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:flutter/foundation.dart';

enum PaygatePlan { yearly, weekly }

/// Что пошло не так — показываем плашкой сверху.
enum PaygateFailure { paymentFailed, nothingToRestore, restoreFailed }

enum PaygateAction { close, subscribed, openTerms, openPrivacy }

/// Пейгейт Cue Plus: тарифы, покупка и восстановление (аналог PaygateViewModel из Swift-проектов).
class PaygateViewModel extends ViewModel<PaygateAction> {
  PaygateViewModel({
    PurchaseManager? purchaseManager,
    this.yearlyId = GlobalDefinitions.paygateYearlyId,
    this.weeklyId = GlobalDefinitions.paygateWeeklyId,
  }) : _purchaseManager = purchaseManager ?? Injector.shared.purchaseManager;

  /// Недель в году — для цены годовой подписки в пересчёте на неделю.
  static const _weeksInYear = 52;

  final String yearlyId;

  final String weeklyId;

  final PurchaseManager _purchaseManager;

  StoreProduct? _yearly;

  StoreProduct? _weekly;

  var _plan = PaygatePlan.yearly;

  var _isLoadingProducts = false;

  var _hasProductsError = false;

  var _isProcessing = false;

  PaygateFailure? _failure;

  StoreProduct? _purchasedProduct;

  StoreProduct? get yearly => _yearly;

  StoreProduct? get weekly => _weekly;

  PaygatePlan get plan => _plan;

  StoreProduct? get selectedProduct => switch (_plan) {
    PaygatePlan.yearly => _yearly,
    PaygatePlan.weekly => _weekly,
  };

  bool get isLoadingProducts => _isLoadingProducts;

  bool get hasProductsError => _hasProductsError;

  /// Идёт покупка или восстановление — экран нельзя закрыть.
  bool get isProcessing => _isProcessing;

  PaygateFailure? get failure => _failure;

  /// Пробный период купленной подписки — для экрана «You’re in».
  int? get purchasedTrialDays => _purchasedProduct?.freeTrialDays;

  /// Выгода годовой подписки относительно недельной: «Save 85%».
  int? get yearlySavingPercent {
    final yearly = _yearly;
    final weekly = _weekly;
    if (yearly == null || weekly == null || weekly.rawPrice <= 0) return null;

    final percent = ((1 - yearly.rawPrice / _weeksInYear / weekly.rawPrice) * 100).floor();
    return percent > 0 ? percent : null;
  }

  /// «$1.15» — годовая подписка в пересчёте на неделю.
  String? get yearlyPricePerWeek => _yearly?.priceDividedBy(_weeksInYear);

  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _hasProductsError = false;
    notifyListeners();

    try {
      if (yearlyId.isEmpty || weeklyId.isEmpty) {
        throw StateError('Paygate product ids are not set in GlobalDefinitions');
      }
      final products = await _purchaseManager.obtainProducts([yearlyId, weeklyId]);
      _yearly = products.where((product) => product.id == yearlyId).firstOrNull;
      _weekly = products.where((product) => product.id == weeklyId).firstOrNull;
      _hasProductsError = _yearly == null || _weekly == null;
    } catch (error) {
      debugPrint('PaygateViewModel: cannot load products: $error');
      _hasProductsError = true;
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  void selectPlan(PaygatePlan plan) {
    if (_isProcessing) return;

    _plan = plan;
    _failure = null;
    notifyListeners();
  }

  Future<void> purchase() async {
    final product = selectedProduct;
    if (product == null || _isProcessing) return;

    await _process(() => _purchaseManager.buy(product), product: product, failure: PaygateFailure.paymentFailed);
  }

  Future<void> restore() async {
    if (_isProcessing) return;

    await _process(
      _purchaseManager.restore,
      failure: PaygateFailure.restoreFailed,
      notSubscribedFailure: PaygateFailure.nothingToRestore,
    );
  }

  void dismissFailure() {
    _failure = null;
    notifyListeners();
  }

  void close() {
    if (!_isProcessing) emit(PaygateAction.close);
  }

  void openTerms() => emit(PaygateAction.openTerms);

  void openPrivacy() => emit(PaygateAction.openPrivacy);

  Future<void> _process(
    Future<PurchaseResult> Function() action, {
    StoreProduct? product,
    required PaygateFailure failure,
    PaygateFailure? notSubscribedFailure,
  }) async {
    _isProcessing = true;
    _failure = null;
    notifyListeners();

    try {
      switch (await action()) {
        case PurchaseResult.subscribed:
          _purchasedProduct = product;
          emit(PaygateAction.subscribed);
        case PurchaseResult.cancelled:
          break;
        case PurchaseResult.notSubscribed:
          _failure = notSubscribedFailure ?? failure;
      }
    } catch (error) {
      debugPrint('PaygateViewModel: $error');
      _failure = failure;
    }

    _isProcessing = false;
    notifyListeners();
  }
}
