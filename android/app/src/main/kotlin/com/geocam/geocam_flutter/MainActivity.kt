package com.geocam.geocam_flutter

import android.media.MediaScannerConnection
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.geocam.geocam_flutter/media_scan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    scanFile(path)
                    result.success(null)
                } else {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                }
            } else if (call.method == "getPicturesDirectory") {
                val path = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES).absolutePath
                result.success(path)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun scanFile(path: String) {
        MediaScannerConnection.scanFile(
            this,
            arrayOf(path),
            null
        ) { _, uri ->
             // Scan completed
        }
    }
}
