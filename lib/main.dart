import 'package:flutter/material.dart';
import 'package:remedi/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/app_entry.dart';
import 'screens/onboarding_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';

/// The entry point of the Remedi application.
/// 
/// This file is responsible for:
/// 1. Initializing the Flutter bindings.
/// 2. Setting up the [NotificationService] to handle local notifications.
/// 3. Checking the onboarding status via [SharedPreferences].
/// 4. Launching the [RemediApp] with the appropriate initial screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App starting...');
  
  // Initialize notification service FIRST
  // This ensures we can handle notification taps even if the app was terminated.
  await NotificationService.initialize();
  debugPrint('✅ NotificationService initialized');

  // Request permissions for notifications
  await NotificationService.requestPermissions();
  debugPrint('✅ Permissions requested');

  // Request exact alarm permission (Android 12+) for precise scheduling
  await NotificationService.requestExactAlarmPermission();
  debugPrint('✅ Exact alarm permission requested');

  // Check Onboarding Status to determine if we show the Intro or Home
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !prefs.containsKey('onboarding_complete');

  runApp(
    ProviderScope(
      child: RemediApp(showOnboarding: showOnboarding),
    ),
  );
}



/// The Root Widget of the application.
/// 
/// It listens to the [themeProvider] to dynamically switch between Light and Dark modes.
class RemediApp extends ConsumerWidget {
  final bool showOnboarding;
  const RemediApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remedi',
      themeMode: themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: showOnboarding ? const OnboardingScreen() : const AppEntry(),
    );
  }
}