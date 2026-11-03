//
//  OtterScaleBridge.swift
//  Runner
//

import Flutter
import OtterScaleiOS

/// Платформенный канал к OtterScaleiOS для Dart-обёртки lib/misc/analytics/otter_scale.dart.
final class OtterScaleBridge: NSObject {
    private let channel: FlutterMethodChannel

    /// Ответы на `initialize`, которые ждут первой валидации чека.
    private var pendingInitializations: [FlutterResult] = []

    private var isInitialized = false

    private var isReady = false

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "dating_assistant/otter_scale", binaryMessenger: messenger)

        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
    }
}

// MARK: OtterScaleReceiptValidationDelegate
extension OtterScaleBridge: OtterScaleReceiptValidationDelegate {
    func otterScaleDidValidatedReceipt(with result: AppStoreValidateResult?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            OtterScale.shared.removeReceiptValidation(delegate: self)
            isReady = true
            pendingInitializations.forEach { $0(nil) }
            pendingInitializations.removeAll()
        }
    }
}

// MARK: Private
private extension OtterScaleBridge {
    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(arguments: call.arguments as? [String: Any], result: result)
        case "get_user_ids":
            result(userIds())
        case "has_active_subscription":
            result(hasActiveSubscription())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Запускает SDK один раз и отвечает после первой валидации чека — как SplashReceiptValidationObserver.
    func initialize(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard !isReady else {
            result(nil)
            return
        }

        guard let host = arguments?["host"] as? String, let apiKey = arguments?["api_key"] as? String else {
            result(FlutterError(code: "invalid_arguments", message: "host and api_key are required", details: nil))
            return
        }

        pendingInitializations.append(result)

        guard !isInitialized else { return }

        isInitialized = true
        OtterScale.shared.addReceiptValidation(delegate: self)
        OtterScale.shared.initialize(host: host, apiKey: apiKey)
    }

    func userIds() -> [String: String] {
        let anonymousId = OtterScale.shared.getAnonymousID()
        let internalId = OtterScale.shared.getInternalID()

        // До покупки SDK отдаёт анонимный идентификатор и вместо внутреннего.
        guard internalId != anonymousId else { return ["anonymous": anonymousId] }

        return ["anonymous": anonymousId, "internal": internalId]
    }

    func hasActiveSubscription() -> Bool {
        guard let paymentData = OtterScale.shared.getPaymentData() else { return false }

        let subscriptions = paymentData.subscriptions.appleAppStore
            + paymentData.subscriptions.googlePlay
            + paymentData.subscriptions.stripe
            + paymentData.subscriptions.paypal
        let nonConsumables = paymentData.nonConsumables.appleAppStore
            + paymentData.nonConsumables.googlePlay
            + paymentData.nonConsumables.stripe
            + paymentData.nonConsumables.paypal

        return subscriptions.contains(where: { $0.valid }) || nonConsumables.contains(where: { $0.valid })
    }
}
