package com.example.dating_assistant

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.ViewGroup
import com.otterscale.analytics.OtterAnalyticsClient
import com.otterscale.analytics.core.toBase64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Платформенный канал к otterscale.aar для Dart-обёртки lib/misc/analytics/otter_scale.dart. */
class OtterScaleBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "dating_assistant/otter_scale")
    private val mainHandler = Handler(Looper.getMainLooper())

    private val client: OtterAnalyticsClient
        get() = OtterAnalyticsClient.getInstance()

    init {
        channel.setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call.argument("host"), call.argument("api_key"), result)
            "get_user_ids" -> result.success(userIds())
            // До инициализации SDK бросает исключение — считаем, что подписки нет.
            "has_active_subscription" -> result.success(runCatching { client.isPaidAccessAvailable }.getOrDefault(false))
            "save_purchase" -> savePurchase(call, result)
            else -> result.notImplemented()
        }
    }

    /** Отдаёт чек Google Play в OtterScale на валидацию, как car_connect; отвечает, когда SDK его проверил. */
    private fun savePurchase(call: MethodCall, result: MethodChannel.Result) {
        val purchaseData = call.argument<String>("purchase_data")
        val productId = call.argument<String>("product_id")
        val price = call.argument<Double>("price")
        val currency = call.argument<String>("currency")
        if (purchaseData == null || productId == null || price == null || currency == null) {
            result.error("invalid_arguments", "purchase_data, product_id, price and currency are required", null)
            return
        }

        try {
            client.savePurchase(purchaseData.toBase64(), productId, price.toFloat(), currency) {
                mainHandler.post { result.success(null) }
            }
        } catch (error: Exception) {
            result.error("save_purchase_failed", error.message, null)
        }
    }

    /** Запускает SDK и регистрирует установку, как в car_connect; отвечает, когда клиент готов. */
    @SuppressLint("HardwareIds")
    private fun initialize(host: String?, apiKey: String?, result: MethodChannel.Result) {
        if (host == null || apiKey == null) {
            result.error("invalid_arguments", "host and api_key are required", null)
            return
        }

        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        val androidId = Settings.Secure.getString(activity.contentResolver, Settings.Secure.ANDROID_ID)
        val reply = { mainHandler.post { result.success(null) } }
        Thread {
            try {
                client.init(activity.applicationContext, apiKey, host) {
                    when {
                        !client.isAppRegistered -> client.registerInstallation(contentView, androidId, null, false) { reply() }
                        !client.isClientReady -> client.reInit { reply() }
                        else -> reply()
                    }
                }
            } catch (error: Exception) {
                mainHandler.post { result.error("initialization_failed", error.message, null) }
            }
        }.start()
    }

    private fun userIds(): Map<String, String> = runCatching {
        val anonymousId = client.anonymousUserID ?: return@runCatching emptyMap<String, String>()
        val internalId = client.internalUserID
        // До покупки SDK отдаёт анонимный идентификатор и вместо внутреннего.
        if (internalId == null || internalId == anonymousId) {
            mapOf("anonymous" to anonymousId)
        } else {
            mapOf("anonymous" to anonymousId, "internal" to internalId)
        }
    }.getOrDefault(emptyMap())
}
