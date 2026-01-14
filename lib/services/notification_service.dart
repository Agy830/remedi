import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'dart:typed_data'; // For Int32List
import '../database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Moved enum to top-level to fix undefined class errors
enum NotificationPriority { low, medium, high }

/// A comprehensive service to handle Local Notifications and Scheduling.
/// 
/// Uses `flutter_local_notifications` to schedule daily reminders for medications.
/// It also handles:
/// - Requesting permissions
/// - Defining notification channels (channels determine sound and vibration behavior)
/// - Handling notification taps (Foregound/Background)
/// - Rescheduling alarms when settings change.
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

  // Preferences Keys
  static const String PREF_SOUND = 'notification_sound'; // 'default', 'loud', 'soft', 'long'
  static const String PREF_PERSISTENT = 'persistent_alarm'; // bool

  // Sound mapping
  static const Map<String, String> soundChannels = {
    'default': 'medication_channel_default',
    'loud': 'medication_channel_loud',
    'soft': 'medication_channel_soft',
    'long': 'medication_channel_long',
  };

  static const Map<String, String> soundNames = {
    'default': 'Default',
    'loud': 'Loud Alarm',
    'soft': 'Soft Chime',
    'long': 'Long Melody',
  };

  // ✅ ADD THIS: Timestamp tracking to prevent duplicate actions
  static final Map<String, int> _actionTimestamps = {};

  static final _actionProcessedController = StreamController<int>.broadcast();
  static Stream<int> get onActionProcessed => _actionProcessedController.stream;

  /// Initializes the plugin and sets up timezone data.
  /// 
  /// Must be called before any other method.
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

          // Try to parse medication ID from payload first (reliable for snoozed notifications)
          int notificationId = response.id!;
          int medicationId = notificationId;

          if (response.payload != null) {
            final payloadId = int.tryParse(response.payload!);
            if (payloadId != null) {
              medicationId = payloadId;
              debugPrint('📦 Recovered original medication ID from payload: $medicationId (notification ID: $notificationId)');
            }
          }

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

    // Create a channel for EACH sound
    for (final entry in soundChannels.entries) {
      final soundKey = entry.key;
      final channelId = entry.value;
      
      // Map sound key to actual resource name (assuming they match file names in res/raw without extension)
      // default -> notification
      // loud -> alarm_loud
      // soft -> alarm_soft
      // long -> alarm_long
      String resourceName = 'notification';
      if (soundKey == 'loud') resourceName = 'alarm_loud';
      if (soundKey == 'soft') resourceName = 'alarm_soft';
      if (soundKey == 'long') resourceName = 'alarm_long';

      await android.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          'Medication Reminders (${soundNames[soundKey]})',
          description: 'Reminders with ${soundNames[soundKey]} sound',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(resourceName),
          enableVibration: true,
        ),
      );
    }
    
    debugPrint('✅ Notification channels created');
  }

  static NotificationDetails _details({
    required String channelId,
    bool persistent = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Medication Reminders',
        channelDescription: 'Reminders for your medication schedule',
        priority: Priority.max,
        importance: Importance.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: true, // If persistent, maybe set this to false? Usually true is fine if tapping opens app
        showWhen: true,
        // Add FLAG_INSISTENT if persistent (loops sound)
        additionalFlags: persistent ? Int32List.fromList([4]) : null, 
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
      
      // ✅ Log history
      await DBHelper().insertLog(medicationId, DateTime.now(), 'TAKEN');
      
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
      
      // Get preferences
      final prefs = await SharedPreferences.getInstance();
      final soundKey = prefs.getString(PREF_SOUND) ?? 'default';
      final persistent = prefs.getBool(PREF_PERSISTENT) ?? false;
      final channelId = soundChannels[soundKey] ?? 'medication_channel_default';

      await notificationsPlugin.zonedSchedule(
        medicationId + 1000 + newCount,
        '⏰ Medication Reminder - Snoozed',
        'Snoozed until $timeString ($newCount/$maxSnooze)',
        snoozeTime,
        _details(channelId: channelId, persistent: persistent),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Added missing parameter
        payload: medicationId.toString(),
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
    
    // Get preferences
    final prefs = await SharedPreferences.getInstance();
    final soundKey = prefs.getString(PREF_SOUND) ?? 'default';
    final persistent = prefs.getBool(PREF_PERSISTENT) ?? false;
    final channelId = soundChannels[soundKey] ?? 'medication_channel_default';

    debugPrint('🔔 Scheduling with sound: $soundKey (channel: $channelId), persistent: $persistent');

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      updatedBody,
      scheduled,
      _details(channelId: channelId, persistent: persistent),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Added missing parameter
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
      minute, // Note: This seems duplicative in original code? Assuming it means 'minute'
    );
    // Correcting parameter call to TZDateTime
    time = tz.TZDateTime(
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

  static Future<void> rescheduleAllNotifications() async {
    debugPrint('🔄 Rescheduling ALL notifications due to settings change...');
    
    // 1. Cancel everything first
    await notificationsPlugin.cancelAll();
    
    // 2. Get all active medications
    final meds = await DBHelper().getAllMedications();
    
    // 3. Re-schedule each
    for (var med in meds) {
      if (!med.isTaken) {
         // Parse time string "HH:MM"
         final parts = med.time.split(':');
         final h = int.parse(parts[0]);
         final m = int.parse(parts[1]);
         
         await scheduleNotification(
           id: med.id!, 
           hour: h, 
           minute: m, 
           title: 'Time to take ${med.name}', 
           body: 'Dosage: ${med.dosage}'
         );
      }
    }
    debugPrint('✅ Rescheduled ${meds.length} medications');
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

  // ================================
  // PREFERENCE GETTERS/SETTERS
  // ================================

  static Future<String> getSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PREF_SOUND) ?? 'default';
  }

  static Future<void> setSoundPreference(String soundKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREF_SOUND, soundKey);
    debugPrint('💾 Saved sound preference: $soundKey');
  }

  static Future<bool> getPersistentPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_PERSISTENT) ?? false;
  }

  static Future<void> setPersistentPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_PERSISTENT, value);
    debugPrint('💾 Saved persistent preference: $value');
  }
}
