package com.example.maquitrace

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "maquitrace/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "showForegroundNotification") {
                    result.notImplemented()
                } else if (Build.VERSION.SDK_INT >= 33 &&
                    checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(false)
                } else {
                    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val channelId = "maquitrace_notices"
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        manager.createNotificationChannel(NotificationChannel(channelId, "Avisos de MaquiTrace", NotificationManager.IMPORTANCE_DEFAULT))
                    }
                    val intent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        android.app.Notification.Builder(this, channelId)
                    } else {
                        @Suppress("DEPRECATION")
                        android.app.Notification.Builder(this)
                    }
                    val notification = builder
                        .setSmallIcon(R.drawable.ic_notification)
                        .setContentTitle("MaquiTrace")
                        .setContentText("Tienes una nueva notificación. Abre la aplicación para verla.")
                        .setContentIntent(pendingIntent)
                        .setAutoCancel(true)
                        .build()
                    manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
                    result.success(true)
                }
            }
    }
}
