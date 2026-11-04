/// Ошибка покупки (аналог IAPError из Swift-проектов).
class PurchaseError implements Exception {
  const PurchaseError(this.code, {this.underlyingError});

  final PurchaseErrorCode code;

  final Object? underlyingError;

  @override
  String toString() => 'PurchaseError(${code.name}, underlying: $underlyingError)';
}

enum PurchaseErrorCode {
  /// Магазин недоступен или не отдал продукты.
  storeUnavailable,

  /// Оплата не прошла.
  paymentFailed,

  /// Магазин не смог восстановить покупки.
  restoreFailed,
}
