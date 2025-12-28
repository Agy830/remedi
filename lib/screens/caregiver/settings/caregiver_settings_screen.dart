import 'package:flutter/material.dart';

class CaregiverSettingsScreen extends StatelessWidget {
  const CaregiverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: const [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.teal,
                child: Text('CG', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              SizedBox(height: 8),
              Text('Caregiver', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('caregiver@email.com', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 12),

        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          trailing: const Text('English'),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    );
  }
}
