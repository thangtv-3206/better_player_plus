package com.jhomlala.better_player_example

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler

class MainActivity : FlutterActivity() {

    private lateinit var pipStatusChannel: EventChannel
    private var eventSink: EventSink? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startNotificationService()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupPipStatusChannel(flutterEngine)
    }

    private fun setupPipStatusChannel(flutterEngine: FlutterEngine) {
        pipStatusChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "better_player_plus/pip_status_event_channel"
        ).apply {
            setStreamHandler(object : StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        var status = Integer.MAX_VALUE
        if (lifecycle.currentState == Lifecycle.State.CREATED) {
            // close button clicked
            status = -1
        } else if (lifecycle.currentState == Lifecycle.State.STARTED || lifecycle.currentState == Lifecycle.State.RESUMED) {
            // resumed if android >= 12, started if android < 12
            status = if (isInPictureInPictureMode) {
                // minimize to pip
                1
            } else {
                // maximize button clicked
                0
            }
        }
        eventSink?.success(status)
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopNotificationService()
    }

    ///TODO: Call this method via channel after remote notification start
    private fun startNotificationService() {
        try {
            val intent = Intent(this, BetterPlayerService::class.java)
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (_: Exception) {
        }
    }

    ///TODO: Call this method via channel after remote notification stop
    private fun stopNotificationService() {
        try {
            val intent = Intent(this, BetterPlayerService::class.java)
            stopService(intent)
        } catch (_: Exception) {

        }
    }
}
