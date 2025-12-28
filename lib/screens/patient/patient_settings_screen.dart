import 'package:flutter/material.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileHeader(),
            const SizedBox(height: 24),

            _sectionTitle('Health'),
            _settingsTile(
              icon: Icons.favorite,
              title: 'Caregivers',
              onTap: () {
                // TODO: Navigate to caregiver connection screen
              },
            ),

            const SizedBox(height: 24),
            _sectionTitle('Settings'),

            _settingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                // TODO: Notification settings
              },
            ),

            _switchTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              value: _darkMode,
              onChanged: (v) {
                setState(() => _darkMode = v);
                // later: ThemeProvider
              },
            ),

            _settingsTile(
              icon: Icons.language,
              title: 'Language',
              trailing: const Text('English'),
              onTap: () {
                // TODO: Language selector
              },
            ),

            const SizedBox(height: 32),

            _logoutTile(),
          ],
        ),
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _profileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.teal,
          child: const Text(
            'JD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'John Doe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'john.doe@email.com',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.teal),
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _logoutTile() {
    return Card(
      color: Colors.red[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () {
          // TODO: Hook Firebase signOut later
        },
      ),
    );
  }
}
