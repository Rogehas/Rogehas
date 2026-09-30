package com.tavas.tavas

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /// Kanal adları sunucu kodundaki (functions/notify.js) ile aynı olmalı.
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel("vefat", "Vefat ilanları", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Yeni vefat ilanları"
            }
        )
        manager.createNotificationChannel(
            NotificationChannel("genel", "Haber ve duyurular", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Haberler, duyurular ve kesinti bildirimleri"
            }
        )
    }
}
