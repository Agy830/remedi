import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../database/db_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 🔁 PENDING ACTION STATE
  static int? _pendingMedicationId;
  static String? _pendingAction;

  static const String actionTaken = 'MARK_TAKEN';
  static const String actionSnooze = 'SNOOZE_10';

  // Add snooze tracking back
  static final Map<int, int> _snoozeCounts = {};
  static const int maxSnooze = 5;

  // ✅ ADD THIS: Timestamp tracking to prevent duplicate actions
  static final Map<String, int> _actionTimestamps = {};

  static final _actionProcessedController = StreamController<int>.broadcast();
  static Stream<int> get onActionProcessed => _actionProcessedController.stream;

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('✅ NotificationService already initialized');
      return;
    }

    debugPrint('🚀 Initializing NotificationService...');
    
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Lagos'));
      debugPrint('✅ Timezone initialized');

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      await notificationsPlugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          debugPrint('🎯 NOTIFICATION TAPPED:');
          debugPrint('   ID: ${response.id}');
          debugPrint('   Action: ${response.actionId}');
          debugPrint('   Payload: ${response.payload}');

          if (response.id == null) {
            debugPrint('❌ No notification ID');
            return;
          }

          final medicationId = response.id!;
          final action = response.actionId;

          // Store pending action ONLY if we don't already have one
          if (_pendingMedicationId == null) {
            _pendingMedicationId = medicationId;
            _pendingAction = action;
            debugPrint('📝 Stored pending action for ID: $medicationId');
          }

          // Handle action immediately
          if (action != null) {
            await _handleAction(medicationId, action);
          } else {
            debugPrint('👆 Notification tapped (no action)');
          }
        },
      );

      await _createChannel();
      _initialized = true;
      
      debugPrint('🎉 NotificationService initialization complete!');
      
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  static Future<void> _createChannel() async {
    final android = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_channel_id',
        'Medication Reminders',
        description: 'Reminders for your medication schedule',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
      ),
    );
    debugPrint('✅ Notification channel created');
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel_id',
        'Medication Reminders',
        channelDescription: 'Reminders for your medication schedule',
        priority: Priority.max,
        importance: Importance.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: true,
        showWhen: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionTaken,
            'Taken',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionSnooze,
            'Snooze 10 min',
            showsUserInterface: true,
          ),
        ],
      ),
    );
  }

  // ✅ ADD THIS: Cleanup method for old timestamps
  static void _cleanupOldTimestamps() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tenMinutesAgo = now - (10 * 60 * 1000);
    
    final initialCount = _actionTimestamps.length;
    _actionTimestamps.removeWhere((key, timestamp) {
      return timestamp < tenMinutesAgo;
    });
    
    final removedCount = initialCount - _actionTimestamps.length;
    if (removedCount > 0) {
      debugPrint('🧹 Cleaned up $removedCount old action timestamps');
    }
  }

  static Future<void> _handleAction(int medicationId, String? action) async {
    debugPrint('🔄 Handling action: $action for medication: $medicationId');
    
    // Clean up old timestamps first
    _cleanupOldTimestamps();
    
    // Check if this action was already processed recently
    final lastActionKey = 'last_action_$medicationId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastActionTime = _actionTimestamps[lastActionKey] ?? 0;
    
    // Prevent processing same action within 2 seconds
    if (now - lastActionTime < 2000) {
      debugPrint('⏸️ Skipping duplicate action (processed ${(now - lastActionTime) / 1000}s ago)');
      return;
    }
    
    // Store the timestamp
    _actionTimestamps[lastActionKey] = now;
    
    if (action == actionTaken) {
      await _markTaken(medicationId);
    } else if (action == actionSnooze) {
      await _snooze(medicationId);
    } else {
      // User tapped notification body - treat as "Taken"
      debugPrint('👆 User tapped notification body, marking as taken');
      await _markTaken(medicationId);
    }
    
    // Notify listeners that an action was processed
    _actionProcessedController.add(medicationId);
  }

  static void dispose() {
    _actionProcessedController.close();
  }

  static Future<void> _markTaken(int medicationId) async {
    debugPrint('✅ MARKING AS TAKEN: $medicationId');
    
    try {
      // 1. Update database
      debugPrint('📊 Updating database for medication: $medicationId');
      await DBHelper().updateTakenStatus(medicationId, true);
      debugPrint('✅ Database updated successfully');
      
      // 2. Cancel all notifications for this medication
      await cancelAllNotificationsForMedication(medicationId);
      debugPrint('🔕 All notifications cancelled');
      
      // 3. Clear snooze count
      resetSnoozeCount(medicationId);
      debugPrint('🔄 Snooze count reset');
      
      // 4. Show confirmation
      await _showConfirmation('Medication marked as taken');
      debugPrint('✅ Marked as taken complete');
      
    } catch (e) {
      debugPrint('❌ Error marking as taken: $e');
      debugPrint('Stack trace: ${e.toString()}');
    }
  }

  static Future<void> _snooze(int medicationId) async {
    debugPrint('⏰ SNOOZING: $medicationId');
    
    try {
      // Get current snooze count
      final count = getSnoozeCount(medicationId);
      debugPrint('📊 Current snooze count: $count/$maxSnooze');
      
      // Check BEFORE incrementing
      if (count >= maxSnooze) {
        debugPrint('🚫 Max snoozes reached, marking as taken');
        await _markTaken(medicationId);
        await _showMaxSnoozeNotification();
        return;
      }
      
      // Calculate new count AFTER checking max
      final newCount = count + 1;
      
      // Update snooze count immediately
      _snoozeCounts[medicationId] = newCount;
      debugPrint('➕ Snooze count set to: $newCount');
      
      // Cancel current notification
      await cancelNotification(medicationId);
      
      // Schedule new notification in 10 minutes
      final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
      
      // Convert to AM/PM format
      final hour = snoozeTime.hour;
      final minute = snoozeTime.minute;
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeString = '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
      
      await notificationsPlugin.zonedSchedule(
        medicationId + 1000 + newCount,
        '⏰ Medication Reminder - Snoozed',
        'Snoozed until $timeString ($newCount/$maxSnooze)',
        snoozeTime,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('✅ Snoozed until $timeString ($newCount/$maxSnooze)');
      
      // Show confirmation with AM/PM format
      await _showConfirmation('Snoozed until $timeString ($newCount/$maxSnooze)');
      
    } catch (e) {
      debugPrint('❌ Error snoozing: $e');
    }
  }

  static Future<void> _showConfirmation(String message) async {
    try {
      // Get current time in AM/PM format
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute;
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeString = '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
      
      await notificationsPlugin.show(
        999999,
        'Remedi - $timeString',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel_id',
            'Medication Reminders',
            importance: Importance.defaultImportance,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing confirmation: $e');
    }
  }

  static Future<void> _showMaxSnoozeNotification() async {
    try {
      await notificationsPlugin.show(
        999998,
        'Maximum Snoozes Reached',
        'You have reached the maximum of $maxSnooze snoozes. Medication marked as taken.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel_id',
            'Medication Reminders',
            importance: Importance.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing max snooze notification: $e');
    }
  }

  // ================================
  // PUBLIC METHODS
  // ================================

  static Future<void> scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    debugPrint('📅 Scheduling notification for ID: $id at $hour:$minute');
    
    final scheduled = _nextTime(hour, minute);
    
    // Convert to AM/PM format for display
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeString = '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
    
    // Update body to include AM/PM time
    final updatedBody = '$body at $timeString';
    
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      updatedBody,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: id.toString(),
    );
    
    debugPrint('✅ Notification scheduled for $timeString');
  }

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var time = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }
    
    debugPrint('⏰ Next scheduled time: $time');
    return time;
  }

  static Future<void> scheduleMultipleNotifications({
    required int medicationId,
    required List<Map<String, int>> times,
    required String title,
    required String body,
  }) async {
    debugPrint('📋 Scheduling ${times.length} notifications for medication: $medicationId');
    
    for (int i = 0; i < times.length; i++) {
      await scheduleNotification(
        id: medicationId,
        hour: times[i]['hour']!,
        minute: times[i]['minute']!,
        title: title,
        body: body,
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    debugPrint('❌ Cancelling notification: $id');
    await notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotificationsForMedication(int medicationId) async {
    debugPrint('❌ Cancelling ALL notifications for medication: $medicationId');
    
    // Cancel main notification
    await notificationsPlugin.cancel(medicationId);
    
    // Cancel all possible snooze notifications (up to maxSnooze)
    for (int i = 0; i <= maxSnooze; i++) {
      await notificationsPlugin.cancel(medicationId + 1000 + i);
    }
    
    debugPrint('✅ All notifications cancelled for medication: $medicationId');
  }

  static Future<void> handlePendingAction() async {
    debugPrint('🔄 Checking for pending actions...');
    
    if (_pendingMedicationId == null || _pendingAction == null) {
      debugPrint('ℹ️ No pending actions');
      return;
    }

    final id = _pendingMedicationId!;
    final action = _pendingAction!;
    
    debugPrint('🔄 Processing pending action: $action for medication: $id');
    
    // Clear pending actions BEFORE processing
    _pendingMedicationId = null;
    _pendingAction = null;
    
    await _handleAction(id, action);
    
    debugPrint('✅ Pending action processed');
  }

  // ================================
  // SNOOZE MANAGEMENT METHODS
  // ================================

  static int getSnoozeCount(int medicationId) {
    return _snoozeCounts[medicationId] ?? 0;
  }

  static void resetSnoozeCount(int medicationId) {
    debugPrint('🔄 Resetting snooze count for medication: $medicationId');
    _snoozeCounts.remove(medicationId);
  }

  // Debug method
  static void debugPrintNotificationInfo() {
    debugPrint('📱 NOTIFICATION SERVICE DEBUG INFO:');
    debugPrint('✅ Initialized: $_initialized');
    debugPrint('🔁 Pending Medication ID: $_pendingMedicationId');
    debugPrint('🔁 Pending Action: $_pendingAction');
    debugPrint('⏰ Snooze Counts: $_snoozeCounts');
    debugPrint('⏱️ Action Timestamps: $_actionTimestamps');
    debugPrint('📊 Max Snooze: $maxSnooze');
    debugPrint('========================');
  }

  // ================================
  // PERMISSION METHODS
  // ================================
  
  static Future<void> requestPermissions() async {
    final android = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    final bool? enabled = await android.areNotificationsEnabled();

    if (enabled == false) {
      debugPrint('❌ Notifications disabled by user');
    } else {
      debugPrint('✅ Notifications already enabled');
    }
  }

  static Future<bool> requestNotificationPermission() async {
    final android = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return true;

    final bool? granted = await android.areNotificationsEnabled();

    if (granted == true) return true;

    await android.requestNotificationsPermission();

    final bool? afterRequest = await android.areNotificationsEnabled();
    return afterRequest ?? false;
  }

  static Future<void> requestExactAlarmPermission() async {
    final android = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    final bool? allowed = await android.canScheduleExactNotifications();
    if (allowed == false) {
      debugPrint('🔔 Requesting exact alarm permission...');
      await android.requestExactAlarmsPermission();
    } else {
      debugPrint('✅ Exact alarm permission already granted');
    }
  }
}