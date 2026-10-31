package com.oppsissora.serenoya

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.oppsissora.serenoya/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "getModel") {
                    result.success(Build.MODEL)
                } else {
                    result.notImplemented()
                }
            }
    }
}
