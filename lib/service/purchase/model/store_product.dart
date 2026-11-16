import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:intl/intl.dart';

/// Подписка из App Store или Google Play (аналог IAPProduct из Swift-проектов).
///
/// Цена — обычная цена подписки, а пробный период — отдельно ([freeTrialDays]), как в App Store.
class StoreProduct {
  const StoreProduct(this.details);

  final ProductDetails details;

  String get id => details.id;

  /// Цена, как её показывает магазин: «$59.99».
  String get price => _googlePlayRegularPrice?.formattedPrice ?? details.price;

  double get rawPrice => switch (_googlePlayRegularPrice) {
    final phase? => phase.priceAmountMicros / 1000000,
    null => details.rawPrice,
  };

  String get currencyCode => _googlePlayRegularPrice?.priceCurrencyCode ?? details.currencyCode;

  /// Обычная цена подписки Google Play — последняя фаза предложения. Плагин берёт цену из первой фазы,
  /// а у предложения с пробным периодом она бесплатная: на пейгейте вышло бы «Free».
  PricingPhaseWrapper? get _googlePlayRegularPrice => switch (details) {
    final GooglePlayProductDetails details => _googlePlayPhases(details)?.lastOrNull,
    _ => null,
  };

  /// Цена за часть периода — «$1.15» в неделю у годовой подписки (аналог Currency с div).
  String priceDividedBy(int divider) => NumberFormat.simpleCurrency(name: currencyCode).format(rawPrice / divider);

  /// Сколько дней длится бесплатный пробный период; null — без пробного периода.
  int? get freeTrialDays => switch (details) {
    final AppStoreProductDetails details => _appStoreTrialDays(details),
    final GooglePlayProductDetails details => _googlePlayTrialDays(details),
    _ => null,
  };

  static int? _appStoreTrialDays(AppStoreProductDetails details) {
    final offer = details.skProduct.introductoryPrice;
    if (offer == null || offer.paymentMode != SKProductDiscountPaymentMode.freeTrail) return null;

    final period = offer.subscriptionPeriod;
    return period.numberOfUnits *
        switch (period.unit) {
          SKSubscriptionPeriodUnit.day => 1,
          SKSubscriptionPeriodUnit.week => 7,
          SKSubscriptionPeriodUnit.month => 30,
          SKSubscriptionPeriodUnit.year => 365,
        };
  }

  /// У подписки Google Play бесплатный период — фаза предложения с нулевой ценой.
  static int? _googlePlayTrialDays(GooglePlayProductDetails details) {
    for (final phase in _googlePlayPhases(details) ?? const <PricingPhaseWrapper>[]) {
      if (phase.priceAmountMicros == 0) return _days(phase.billingPeriod);
    }
    return null;
  }

  /// Фазы цены у предложения подписки Google Play по порядку: пробный период, вводная цена, обычная цена.
  /// null — у продукта нет предложений, это разовая покупка.
  static List<PricingPhaseWrapper>? _googlePlayPhases(GooglePlayProductDetails details) {
    final offers = details.productDetails.subscriptionOfferDetails;
    final index = details.subscriptionIndex;
    if (offers == null || index == null) return null;

    return offers[index].pricingPhases;
  }

  /// Длительность в днях из ISO 8601: «P3D», «P1W», «P1M».
  static int? _days(String period) {
    final match = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(period);
    if (match == null) return null;

    int part(int group) => int.tryParse(match[group] ?? '') ?? 0;
    return part(1) * 365 + part(2) * 30 + part(3) * 7 + part(4);
  }
}
