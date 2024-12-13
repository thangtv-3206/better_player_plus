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
    private val PADDING_TOP_KEY = 2131364639

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        startNotificationService()
        addContentView(
            ConstraintLayout(this).apply {
                tag = PIP_CONTAINER
                isVisible = false
                setBackgroundColor(Color.WHITE)
            }, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
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

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        window.decorView.findViewWithTag<ViewGroup>(PIP_CONTAINER).let {
            if (isInPictureInPictureMode) {
                it.isVisible = true
                findViewById<ViewGroup>(FLUTTER_VIEW_ID)?.isVisible = false
            } else {
                findViewById<ViewGroup>(FLUTTER_VIEW_ID)?.isVisible = true
                (it.getTag(PADDING_TOP_KEY) as? Int?)?.let { top ->
                    it.setPadding(0, top, 0, 0)
                }
                it.postDelayed(750) {
                    it.isVisible = false
                    it.setPadding(0, 0, 0, 0)
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        if (!isInPictureInPictureMode) {
            findViewById<ViewGroup>(FLUTTER_VIEW_ID)?.isVisible = true
        }
    }
}
