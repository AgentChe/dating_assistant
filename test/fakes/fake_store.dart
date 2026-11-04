import 'dart:async';

import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

/// Магазин для тестов: отдаёт заданные продукты, а на покупку присылает [nextPurchaseStatus].
class FakeStore extends InAppPurchasePlatform {
  FakeStore({this.isStoreAvailable = true, this.products = const []});

  final bool isStoreAvailable;

  final List<ProductDetails> products;

  /// Что магазин пришлёт после покупки; null — ничего, окно оплаты как будто ещё открыто.
  PurchaseStatus? nextPurchaseStatus = PurchaseStatus.purchased;

  /// Что пришлёт восстановление покупок.
  List<PurchaseDetails> restoredPurchases = [];

  final completedPurchases = <PurchaseDetails>[];

  final _purchaseUpdates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseUpdates.stream;

  @override
  Future<bool> isAvailable() async => isStoreAvailable;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async => ProductDetailsResponse(
    productDetails: [
      for (final product in products)
        if (identifiers.contains(product.id)) product,
    ],
    notFoundIDs: [
      for (final id in identifiers)
        if (!products.any((product) => product.id == id)) id,
    ],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    final status = nextPurchaseStatus;
    if (status != null) {
      scheduleMicrotask(() => _purchaseUpdates.add([purchase(purchaseParam.productDetails.id, status)]));
    }
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (restoredPurchases.isNotEmpty) _purchaseUpdates.add(restoredPurchases);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completedPurchases.add(purchase);

  static PurchaseDetails purchase(String productId, PurchaseStatus status) =>
      PurchaseDetails(
          purchaseID: 'order-$productId',
          productID: productId,
          verificationData: PurchaseVerificationData(
            localVerificationData: '{"orderId":"order-$productId"}',
            serverVerificationData: 'token-$productId',
            source: 'google_play',
          ),
          transactionDate: '1700000000000',
          status: status,
        )
        ..pendingCompletePurchase = status != PurchaseStatus.pending
        ..error = status == PurchaseStatus.error
            ? IAPError(source: 'google_play', code: 'failed', message: 'Payment failed')
            : null;
}

/// Подписка без пробного периода — как её отдаёт магазин.
ProductDetails fakeProduct(String id, double price) => ProductDetails(
  id: id,
  title: id,
  description: '',
  price: '\$${price.toStringAsFixed(2)}',
  rawPrice: price,
  currencyCode: 'USD',
  currencySymbol: r'$',
);
