/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

package com.finnesia.pos

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder

/**
 * Posts the open-shift reminder when the cashier swipes the app away from Recents.
 *
 * Swiping a task away kills the app without telling Flutter anything, so the reminder cannot be
 * a dialog. What Android does tell is a *started* service of the same task: [onTaskRemoved] runs
 * (that is why the manifest declares `stopWithTask="false"`). This service exists only for that
 * moment. `MainActivity` starts it with the reminder's text, already in the cashier's language,
 * while there is an open shift to remind of, and stops it when there is not.
 *
 * Limits, accepted: Android stops a background app's started services about a minute after it
 * leaves the foreground, so a swipe long after the app was put away arrives with no service left
 * to hear it. And without the notification permission (Android 13+) there is nothing to post.
 */
class ShiftReminderService : Service() {
    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        private const val CHANNEL_ID = "finnesia_pos_shift_reminder"
        private const val NOTIFICATION_ID = 4201
    }

    private var title: String? = null
    private var body: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Each start carries the latest text: a change of shift or of language starts it again.
        title = intent?.getStringExtra(EXTRA_TITLE)
        body = intent?.getStringExtra(EXTRA_BODY)
        // Not sticky: a service the system restarts later, with no task and no text, would have
        // nothing to say.
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val reminderTitle = title
        val reminderBody = body
        if (reminderTitle != null && reminderBody != null) {
            post(reminderTitle, reminderBody)
        }
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    private fun post(reminderTitle: String, reminderBody: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val manager = getSystemService(NotificationManager::class.java) ?: return
        // Named after the reminder itself, in the cashier's language: it is what the cashier sees
        // for this channel in the system's notification settings.
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, reminderTitle, NotificationManager.IMPORTANCE_HIGH),
        )
        // Tapping it opens the app again, where the shift gate's "already open" panel is waiting.
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(reminderTitle)
            .setContentText(reminderBody)
            .setStyle(Notification.BigTextStyle().bigText(reminderBody))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }
}
