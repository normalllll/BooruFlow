package io.github.normalllll.yande_gui

import android.app.*
import android.content.*
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.os.*
import androidx.core.app.NotificationCompat
import androidx.core.graphics.createBitmap

class DownloadForegroundService : Service() {
    companion object {
        private var instance: DownloadForegroundService? = null
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "download_channel"

        fun updateNotification(title: String, text: String, progress: Int?) {
            instance?.let { service ->
                val notification = service.buildNotification(title, text, progress)
                val manager = service.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, notification)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "Title"
        val text = intent?.getStringExtra("text") ?: "Running..."
        val receiver = intent?.getParcelableExtra<ResultReceiver>("receiver")

        val notification = buildNotification(title, text, null)

        startForeground(NOTIFICATION_ID, notification)

        receiver?.send(Activity.RESULT_OK, Bundle())
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun getAppLargeIconBitmap(): Bitmap? {
        val icon = applicationInfo.loadIcon(packageManager)
        return when (icon) {
            is BitmapDrawable -> icon.bitmap
            is AdaptiveIconDrawable -> {
                val size = resources.getDimensionPixelSize(android.R.dimen.notification_large_icon_width)
                val bitmap = createBitmap(size, size)
                val canvas = Canvas(bitmap)
                icon.setBounds(0, 0, size, size)
                icon.draw(canvas)
                bitmap
            }
            else -> null
        }
    }


    private fun buildNotification(title: String, text: String, progress: Int?): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(applicationInfo.icon)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)


        val largeIcon = getAppLargeIconBitmap()
        if (largeIcon != null) {
            builder.setLargeIcon(largeIcon)
        }

        if (progress != null) {
            builder.setProgress(100, progress, false)
        } else {
            builder.setProgress(0, 0, true)
        }

        return builder.build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Download Foreground Service",
            NotificationManager.IMPORTANCE_LOW,
        )
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }
}
