package com.jhomlala.better_player_example

import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.ViewGroup
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import androidx.core.view.postDelayed
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val PIP_CONTAINER = "PIP_CONTAINER"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        startNotificationService()
        addContentView(
            ConstraintLayout(this).apply {
                tag = PIP_CONTAINER
                isVisible = false
                elevation = 99F
                setBackgroundColor(Color.BLACK)
            }, ConstraintLayout.LayoutParams(
                ConstraintLayout.LayoutParams.MATCH_PARENT,
                ConstraintLayout.LayoutParams.WRAP_CONTENT
            )
        )
    }

    override fun onDestroy() {
        super.onDestroy()
//        stopNotificationService()
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

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        window.decorView.findViewWithTag<ViewGroup>(PIP_CONTAINER).let {
            if (isInPictureInPictureMode) {
                it.isVisible = true
            } else {
                it.postDelayed(200) {
                    it.isVisible = false
                }
            }
        }
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    }
}
