import 'package:flutter/material.dart';
import 'package:remedi/services/notification_service.dart';
import 'screens/app_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App starting...');
  
  // Initialize notification service FIRST
  await NotificationService.initialize();
  debugPrint('✅ NotificationService initialized');

  // Request permissions
  await NotificationService.requestPermissions();
  debugPrint('✅ Permissions requested');

  // Request exact alarm permission (Android 12+)
  await NotificationService.requestExactAlarmPermission();
  debugPrint('✅ Exact alarm permission requested');

  runApp(const RemediApp());
}

class RemediApp extends StatelessWidget {
  const RemediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remedi',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const AppEntry(),
    );
  }
}