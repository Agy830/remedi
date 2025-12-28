// services/alarm_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('medication_reminder/alarm');
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the alarm service
  static Future<void> initialize() async {
    try {
      // Initialize notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings);
      
      await notificationsPlugin.initialize(initializationSettings);
      
      debugPrint('🔔 Alarm service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing alarm service: $e');
    }
  }

  // Schedule an alarm using Android's AlarmManager
  static Future<void> scheduleAlarm({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      // Calculate timestamp for the alarm
      final now = DateTime.now();
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the time has passed, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      
      final timestamp = alarmTime.millisecondsSinceEpoch;
      
      debugPrint('⏰ Scheduling alarm $id for ${alarmTime.hour}:${alarmTime.minute}');
      
      // Call native Android code to schedule the alarm
      await _channel.invokeMethod('scheduleAlarm', {
        'id': id,
        'timestamp': timestamp,
        'title': title,
        'body': body,
      });
      
      debugPrint('✅ Alarm $id scheduled successfully!');
    } catch (e) {
      debugPrint('❌ Error scheduling alarm: $e');
    }
  }

  // Test alarm in 2 minutes
  static Future<void> testAlarm() async {
    try {
      final alarmTime = DateTime.now().add(const Duration(minutes: 2));
      final timestamp = alarmTime.millisecondsSinceEpoch;
      
      debugPrint('🧪 Testing alarm in 2 minutes...');
      
      await _channel.invokeMethod('scheduleAlarm', {
        'id': 999,
        'timestamp': timestamp,
        'title': 'Test Alarm (2 min)',
        'body': 'This is a test alarm scheduled via Android AlarmManager',
      });
      
      debugPrint('✅ Test alarm scheduled!');
    } catch (e) {
      debugPrint('❌ Test alarm failed: $e');
    }
  }

  // Cancel an alarm
  static Future<void> cancelAlarm(int id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
      debugPrint('🗑️ Alarm $id cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling alarm: $e');
    }
  }
}