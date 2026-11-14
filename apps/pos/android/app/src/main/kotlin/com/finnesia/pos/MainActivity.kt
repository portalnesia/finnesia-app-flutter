package com.finnesia.pos

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // `pos/exit_notice` (`exit_notice_channel.dart`): keeps ShiftReminderService running with
        // the open-shift reminder while there is one, so a swipe from Recents can still post it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pos/exit_notice")
            .setMethodCallHandler { call, result ->
                val service = Intent(this, ShiftReminderService::class.java)
                when (call.method) {
                    "set" -> {
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        if (title == null || body == null) {
                            result.error("bad_args", "title and body are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            startService(
                                service
                                    .putExtra(ShiftReminderService.EXTRA_TITLE, title)
                                    .putExtra(ShiftReminderService.EXTRA_BODY, body),
                            )
                            result.success(null)
                        } catch (failure: IllegalStateException) {
                            // Android refuses to start a service for an app in the background.
                            result.error("not_started", failure.message, null)
                        }
                    }
                    "clear" -> {
                        stopService(service)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
