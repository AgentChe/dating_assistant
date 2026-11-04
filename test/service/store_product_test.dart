import 'package:dating_assistant/service/purchase/model/store_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../fakes/fake_store.dart';

void main() {
  test('App Store: the free trial comes from the introductory offer', () {
    final locale = SKPriceLocaleWrapper(currencySymbol: r'$', currencyCode: 'USD', countryCode: 'US');
    final product = StoreProduct(
      AppStoreProductDetails.fromSKProduct(
        SKProductWrapper(
          productIdentifier: 'yearly',
          localizedTitle: 'Yearly',
          localizedDescription: '',
          priceLocale: locale,
          price: '59.99',
          introductoryPrice: SKProductDiscountWrapper(
            price: '0',
            priceLocale: locale,
            numberOfPeriods: 1,
            paymentMode: SKProductDiscountPaymentMode.freeTrail,
            subscriptionPeriod: SKProductSubscriptionPeriodWrapper(
              numberOfUnits: 3,
              unit: SKSubscriptionPeriodUnit.day,
            ),
            identifier: 'trial',
            type: SKProductDiscountType.introductory,
          ),
        ),
      ),
    );

    expect(product.freeTrialDays, 3);
  });

  test('Google Play: the free trial is the zero-priced phase of the offer', () {
    PricingPhaseWrapper yearlyPhase() => const PricingPhaseWrapper(
      billingCycleCount: 0,
      billingPeriod: 'P1Y',
      formattedPrice: r'$59.99',
      priceAmountMicros: 59990000,
      priceCurrencyCode: 'USD',
      recurrenceMode: RecurrenceMode.infiniteRecurring,
    );
    final offers = GooglePlayProductDetails.fromProductDetails(
      ProductDetailsWrapper(
        description: '',
        name: 'Yearly',
        productId: 'yearly',
        productType: ProductType.subs,
        title: 'Yearly',
        subscriptionOfferDetails: [
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'yearly',
            offerId: 'trial',
            offerTags: const [],
            offerIdToken: 'trial-token',
            pricingPhases: [
              const PricingPhaseWrapper(
                billingCycleCount: 1,
                billingPeriod: 'P1W',
                formattedPrice: 'Free',
                priceAmountMicros: 0,
                priceCurrencyCode: 'USD',
                recurrenceMode: RecurrenceMode.finiteRecurring,
              ),
              yearlyPhase(),
            ],
          ),
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'yearly',
            offerTags: const [],
            offerIdToken: 'base-token',
            pricingPhases: [yearlyPhase()],
          ),
        ],
      ),
    );

    expect(offers.map((offer) => StoreProduct(offer).freeTrialDays), [7, null]);
  });

  test('a yearly price per week', () {
    expect(StoreProduct(fakeProduct('yearly', 59.99)).priceDividedBy(52), r'$1.15');
  });
}
