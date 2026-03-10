import 'package:flutter/material.dart';
import 'package:remedi/screens/caregiver/dashboard/caregiver_dashboard_screen.dart';
import 'settings/caregiver_settings_screen.dart';

class CaregiverShell extends StatefulWidget {
  const CaregiverShell({super.key});

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _currentIndex = 0;

  final _pages = const [
    CaregiverDashboardScreen(), // 0
    CaregiverSettingsScreen(),  // 1
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(child: _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: Colors.teal,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
