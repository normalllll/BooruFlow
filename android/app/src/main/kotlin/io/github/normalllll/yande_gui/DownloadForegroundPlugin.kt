package io.github.normalllll.yande_gui

import android.app.Activity
import android.content.*
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DownloadForegroundPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "foreground_service_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startService" -> {
                val title = call.argument<String>("title") ?: "Foreground Service"
                val text = call.argument<String>("text") ?: "Running..."

                val receiver = object : ResultReceiver(Handler(Looper.getMainLooper())) {
                    override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                        if (resultCode == Activity.RESULT_OK) {
                            result.success(true)
                        } else {
                            result.error("SERVICE_ERROR", "Service failed to start", null)
                        }
                    }
                }

                val intent = Intent(context, DownloadForegroundService::class.java).apply {
                    putExtra("title", title)
                    putExtra("text", text)
                    putExtra("receiver", receiver)
                }
                ContextCompat.startForegroundService(context, intent)
            }

            "stopService" -> {
                val intent = Intent(context, DownloadForegroundService::class.java)
                context.stopService(intent)
                result.success(true)
            }

            "updateProgress" -> {
                val title = call.argument<String>("title") ?: ""
                val text = call.argument<String>("text") ?: ""
                val progress = call.argument<Int>("progress") // nullable
                DownloadForegroundService.updateNotification(title, text, progress)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }
}

