import 'dart:async';

import 'package:dating_assistant/misc/analytics/otter_scale.dart';
import 'package:dating_assistant/service/purchase/model/purchase_error.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/model/store_product.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

/// Покупки в App Store и Google Play (аналог IAPManager и PaygateInteractor из Swift-проектов).
///
/// Магазин присылает покупки в общий поток — и без действий пользователя (продления,
/// незавершённые покупки), поэтому менеджер слушает его с запуска приложения ([start]).
/// Каждую покупку он отдаёт на валидацию в OtterScale и подтверждает магазину, а покупка
/// и восстановление завершаются, когда OtterScale провалидировал чек.
class PurchaseManager {
  PurchaseManager({required SessionManager sessionManager, OtterScale? otterScale})
    : _sessionManager = sessionManager,
      _otterScale = otterScale ?? OtterScale.shared;

  /// Сколько ждём валидацию чека, прежде чем проверить подписку как есть.
  static const _validationTimeout = Duration(seconds: 30);

  /// Сколько ждём восстановленные покупки после того, как магазин закончил восстановление.
  static const _restoredPurchasesDelay = Duration(milliseconds: 500);

  final SessionManager _sessionManager;

  final OtterScale _otterScale;

  /// Загруженные продукты: с чеком Google Play OtterScale нужны цена и валюта.
  final _products = <String, StoreProduct>{};

  /// Покупки, которые уже отданы в OtterScale: магазин присылает одну и ту же несколько раз.
  final _deliveredPurchases = <String>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdates;

  StreamSubscription<void>? _receiptValidations;

  /// Покупка или восстановление, которое ждёт результата.
  Completer<PurchaseResult>? _pending;

  /// Магазин прислал покупку для [_pending] — ждём, пока OtterScale проверит чек.
  var _isAwaitingValidation = false;

  Timer? _validationTimeoutTimer;

  /// В текущем восстановлении магазин прислал хотя бы одну покупку.
  var _hasRestoredPurchases = false;

  InAppPurchasePlatform get _store => InAppPurchasePlatform.instance;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Подключает магазин платформы; вызывается в main до первого обращения к покупкам.
  static Future<void> registerStore() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // OtterScaleiOS слушает очередь StoreKit 1, поэтому плагин переключаем на неё, как в car_connect.
        // ignore: deprecated_member_use
        await InAppPurchaseStoreKitPlatform.enableStoreKit1();
        InAppPurchaseStoreKitPlatform.registerPlatform();
      case TargetPlatform.android:
        InAppPurchaseAndroidPlatform.registerPlatform();
      default:
        break;
    }
  }

  /// Начинает слушать магазин (аналог IAPManager.initialize).
  void start() {
    _purchaseUpdates ??= _store.purchaseStream.listen(_onPurchasesUpdated, onError: _onStoreError);
    _receiptValidations ??= _otterScale.receiptValidations.listen((_) => _onReceiptValidated());
  }

  /// Продукты в порядке [ids]; тех, что магазин не нашёл, в списке нет.
  Future<List<StoreProduct>> obtainProducts(List<String> ids) async {
    if (!await _store.isAvailable()) throw const PurchaseError(PurchaseErrorCode.storeUnavailable);

    final response = await _store.queryProductDetails(ids.toSet());
    final error = response.error;
    if (error != null) throw PurchaseError(PurchaseErrorCode.storeUnavailable, underlyingError: error);

    // У подписки Google Play бывает несколько предложений — берём то, где дольше бесплатный период.
    for (final details in response.productDetails) {
      final product = StoreProduct(details);
      final current = _products[product.id];
      if (current == null || (product.freeTrialDays ?? 0) > (current.freeTrialDays ?? 0)) {
        _products[product.id] = product;
      }
    }
    return [for (final id in ids) ?_products[id]];
  }

  /// Покупает подписку и ждёт, пока OtterScale провалидирует чек.
  Future<PurchaseResult> buy(StoreProduct product) async {
    final result = _begin();
    try {
      final isStarted = await _store.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product.details));
      if (!isStarted) _finish(error: const PurchaseError(PurchaseErrorCode.paymentFailed));
    } catch (error) {
      _finish(error: PurchaseError(PurchaseErrorCode.paymentFailed, underlyingError: error));
    }
    return result;
  }

  /// Восстанавливает покупки; если восстанавливать нечего — [PurchaseResult.notSubscribed].
  Future<PurchaseResult> restore() async {
    final result = _begin();
    _hasRestoredPurchases = false;
    try {
      await _store.restorePurchases();
      // Восстановленные покупки приходят в поток отдельным событием — даём им дойти.
      await Future<void>.delayed(_restoredPurchasesDelay);
      if (!_hasRestoredPurchases) _finish(result: PurchaseResult.notSubscribed);
    } catch (error) {
      _finish(error: PurchaseError(PurchaseErrorCode.restoreFailed, underlyingError: error));
    }
    return result;
  }

  Future<PurchaseResult> _begin() {
    if (_pending != null) throw StateError('A purchase or restore is already in progress');

    final pending = _pending = Completer<PurchaseResult>();
    _isAwaitingValidation = false;
    return pending.future;
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          await _complete(purchase);
          _finish(result: PurchaseResult.cancelled);
        case PurchaseStatus.error:
          await _complete(purchase);
          _finish(error: PurchaseError(PurchaseErrorCode.paymentFailed, underlyingError: purchase.error));
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _hasRestoredPurchases = true;
          await _deliver(purchase);
      }
    }
  }

  /// Отдаёт покупку на валидацию в OtterScale и подтверждает магазину — по разу на покупку.
  Future<void> _deliver(PurchaseDetails purchase) async {
    final key = '${purchase.productID}:${purchase.purchaseID ?? purchase.transactionDate}';
    if (!_deliveredPurchases.add(key)) {
      // Эту покупку OtterScale уже проверял — достаточно свериться с подпиской.
      await _complete(purchase);
      await _finishWithSubscriptionStatus();
      return;
    }

    try {
      if (!_sessionManager.isEnabled) {
        // Без ключа OtterScale чек проверить некому: подтверждаем покупку и проверяем подписку как есть.
        await _complete(purchase);
        await _finishWithSubscriptionStatus();
      } else if (_isIOS) {
        // Чек iOS OtterScaleiOS проверяет сам, подтверждаем покупку и ждём от него события.
        _awaitValidation();
        await _complete(purchase);
      } else {
        final product = _products[purchase.productID];
        await _otterScale.savePurchase(
          purchaseData: purchase.verificationData.localVerificationData,
          productId: purchase.productID,
          price: product?.rawPrice ?? 0,
          currency: product?.currencyCode ?? '',
        );
        await _complete(purchase);
        await _finishWithSubscriptionStatus();
      }
    } catch (error) {
      _deliveredPurchases.remove(key);
      _finish(error: PurchaseError(PurchaseErrorCode.paymentFailed, underlyingError: error));
    }
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) await _store.completePurchase(purchase);
  }

  void _awaitValidation() {
    if (_pending == null) return;

    _isAwaitingValidation = true;
    _validationTimeoutTimer?.cancel();
    _validationTimeoutTimer = Timer(_validationTimeout, _finishWithSubscriptionStatus);
  }

  void _onReceiptValidated() {
    if (_isAwaitingValidation) _finishWithSubscriptionStatus();
  }

  Future<void> _finishWithSubscriptionStatus() async {
    if (_pending == null) return;

    _isAwaitingValidation = false;
    _validationTimeoutTimer?.cancel();
    await _sessionManager.refreshUserIds();
    final isSubscribed = await _sessionManager.hasActiveSubscriptions();
    _finish(result: isSubscribed ? PurchaseResult.subscribed : PurchaseResult.notSubscribed);
  }

  void _onStoreError(Object error) {
    _finish(error: PurchaseError(PurchaseErrorCode.paymentFailed, underlyingError: error));
  }

  void _finish({PurchaseResult? result, PurchaseError? error}) {
    final pending = _pending;
    if (pending == null) return;

    _pending = null;
    _isAwaitingValidation = false;
    _validationTimeoutTimer?.cancel();
    if (error != null) {
      pending.completeError(error);
    } else {
      pending.complete(result ?? PurchaseResult.notSubscribed);
    }
  }
}
