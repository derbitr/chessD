package com.chessd.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.chessd.app/system"
        private const val UPDATE_CHANNEL_ID = "chessd_updates"
        private const val NOTIFICATION_PERMISSION_REQUEST = 1001
        private const val UPDATE_NOTIFICATION_ID = 1004
    }

    private var pendingNotifTitle: String? = null
    private var pendingNotifBody: String? = null
    private var pendingNotifUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    result.success(openExternalUrl(url))
                }
                "requestNotificationPermission" -> {
                    result.success(ensureNotificationPermission(requestIfMissing = true))
                }
                "showUpdateNotification" -> {
                    val title = call.argument<String>("title") ?: "Nova versao disponivel no chessD"
                    val body = call.argument<String>("body") ?: "Toque para baixar a nova versao."
                    val url = call.argument<String>("url") ?: "https://github.com/derbitr/chessD/releases"

                    if (!ensureNotificationPermission(requestIfMissing = true)) {
                        pendingNotifTitle = title
                        pendingNotifBody = body
                        pendingNotifUrl = url
                        result.success(false)
                    } else {
                        result.success(postUpdateNotification(title, body, url))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openExternalUrl(url: String?): Boolean {
        if (url.isNullOrBlank()) return false
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun ensureNotificationPermission(requestIfMissing: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < 33) return true
        val permission = "android.permission.POST_NOTIFICATIONS"
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            return true
        }
        if (requestIfMissing) {
            requestPermissions(arrayOf(permission), NOTIFICATION_PERMISSION_REQUEST)
        }
        return false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            val title = pendingNotifTitle
            val body = pendingNotifBody
            val url = pendingNotifUrl
            pendingNotifTitle = null
            pendingNotifBody = null
            pendingNotifUrl = null
            if (title != null && body != null && url != null) {
                postUpdateNotification(title, body, url)
            }
        }
    }

    private fun postUpdateNotification(title: String, body: String, url: String): Boolean {
        return try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    UPDATE_CHANNEL_ID,
                    "Atualizacoes do chessD",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alertas quando uma nova versao do chessD for lancada."
                    enableLights(true)
                    enableVibration(true)
                }
                manager.createNotificationChannel(channel)
            }

            val tapIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, 2001, tapIntent, flags)

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, UPDATE_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder
                .setSmallIcon(android.R.drawable.stat_sys_download_done)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setPriority(Notification.PRIORITY_HIGH)
            }

            manager.notify(UPDATE_NOTIFICATION_ID, builder.build())
            true
        } catch (_: Exception) {
            false
        }
    }
}
