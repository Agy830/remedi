import 'package:flutter/material.dart';
import 'package:remedi/services/notification_service.dart';
import 'screens/app_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await NotificationService.requestExactAlarmPermission();


  
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
