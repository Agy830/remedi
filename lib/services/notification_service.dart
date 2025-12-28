// services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../database/db_helper.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ================================
  // 🔔 ACTION CONSTANTS  (NEW)
  // ================================
  static const String ACTION_TAKEN = 'MARK_TAKEN';
  static const String ACTION_SNOOZE = 'SNOOZE_10';

  // Snooze tracking (NEW)
  static final Map<int, int> _snoozeCounts = {};
  static const int MAX_SNOOZE = 5;

  // ================================
  // PERMISSIONS
  // ================================
  static Future<bool> requestPermissions() async {
    try {
      debugPrint('🔔 Requesting notification permissions...');
      return true;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  // ================================
  // INITIALIZATION
  // ================================
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🚀 Initializing notification service...');

      // ✅ TIMEZONE (KEEP)
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Lagos'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ================================
      // 🔔 ACTION HANDLER (NEW)
      // ================================
      await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) async {
          final actionId = response.actionId;
          final id = response.id;

          if (id == null) return;

          if (actionId == ACTION_TAKEN) {
            await _handleMarkTaken(id);
          }

          if (actionId == ACTION_SNOOZE) {
            await _handleSnooze(id);
          }
        },
      );

      await _createNotificationChannel();
      _initialized = true;

      debugPrint('✅ Notification service ready');
    } catch (e) {
      debugPrint('❌ Init error: $e');
    }
  }

  // ================================
  // ANDROID CHANNEL
  // ================================
  static Future<void> _createNotificationChannel() async {
    final android =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_channel_id',
        'Medication Reminders',
        description: 'Medication schedule reminders',
        importance: Importance.max,
      ),
    );
  }

  // ================================
  // NOTIFICATION DETAILS (NEW)
  // ================================
  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel_id',
        'Medication Reminders',
        importance: Importance.max,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            ACTION_TAKEN,
            'Taken',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            ACTION_SNOOZE,
            'Snooze 10 min',
            showsUserInterface: false,
          ),
        ],
      ),
    );
  }

  // ================================
  // SCHEDULE MULTIPLE
  // ================================
  static Future<void> scheduleMultipleNotifications({
    required List<Map<String, int>> times,
    required String title,
    required String body,
  }) async {
    for (int i = 0; i < times.length; i++) {
      await scheduleNotification(
        id: i,
        hour: times[i]['hour']!,
        minute: times[i]['minute']!,
        title: title,
        body: body,
      );
    }
  }

  // ================================
  // SCHEDULE SINGLE
  // ================================
  static Future<void> scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduledTime = _calculateScheduleTime(hour, minute);

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ================================
  // TIME CALCULATION (KEEP)
  // ================================
  static tz.TZDateTime _calculateScheduleTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.difference(now).inSeconds < 120) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // ================================
  // ✅ MARK AS TAKEN (NEW)
  // ================================
  static Future<void> _handleMarkTaken(int id) async {
    final db = DBHelper();

    await db.updateTakenStatus(id, true);
    await notificationsPlugin.cancel(id);

    _snoozeCounts.remove(id);

    debugPrint('✅ Medication $id marked as taken');
  }

  // ================================
  // ⏰ SNOOZE (NEW)
  // ================================
  static Future<void> _handleSnooze(int id) async {
    final count = _snoozeCounts[id] ?? 0;

    if (count >= MAX_SNOOZE) {
      debugPrint('⛔ Snooze limit reached');
      return;
    }

    _snoozeCounts[id] = count + 1;

    final snoozeTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

    await notificationsPlugin.zonedSchedule(
      id,
      'Medication Reminder (Snoozed)',
      'Please take your medication',
      snoozeTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('⏰ Snoozed ($count/$MAX_SNOOZE)');
  }

  // ================================
  // CANCEL HELPERS
  // ================================
  static Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  // ================================
  // EXACT ALARM PERMISSION
  // ================================
  static Future<void> requestExactAlarmPermission() async {
  final android = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (android == null) return;

  final bool? allowed = await android.canScheduleExactNotifications();

  if (allowed == false) {
    await android.requestExactAlarmsPermission();
  }
}

}