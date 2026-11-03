package com.example.dating_assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var otterScaleBridge: OtterScaleBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        otterScaleBridge = OtterScaleBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
