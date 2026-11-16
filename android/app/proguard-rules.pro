# Правила R8 для release-сборки Android: Flutter подключает этот файл сам.
# Взяты из car_connect, где работает тот же OtterScale SDK (android/app/libs/otterscale.aar).

-keepattributes SourceFile,LineNumberTable

# OtterScale целиком: модели ответов его сервера Gson заполняет через рефлексию.
-keep class com.otterscale.** { *; }
-keepclassmembers class com.otterscale.** { *; }

-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Retrofit, через который OtterScale подтверждает покупку, читает аннотации @GET/@POST/@Body
# через рефлексию. Без этих правил R8 их вырезает, и в release подтверждение покупки молча ломается.
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,RuntimeInvisibleAnnotations
-keep @interface retrofit2.http.**
-keep class retrofit2.**

# OtterScale запускает корутины, а Pigeon-мост in_app_purchase_android использует kotlin.Result и kotlin.Unit.
-keep class kotlinx.coroutines.**
-keep class kotlin.Result { *; }
-keep class kotlin.Unit { *; }

# OtterScale ссылается на старые API Billing Library, которых нет в версии 8.
-dontwarn com.android.billingclient.api.QueryPurchaseHistoryParams$Builder
-dontwarn com.android.billingclient.api.QueryPurchaseHistoryParams
-dontwarn com.android.billingclient.api.SkuDetails
-dontwarn com.android.billingclient.api.SkuDetailsResponseListener
-dontwarn com.android.billingclient.api.SkuDetailsParams
-dontwarn com.android.billingclient.api.SkuDetailsParams$Builder
