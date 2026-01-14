import 'package:flutter/material.dart';

/// Settings screen for the Caregiver profile.
/// 
/// Allows the caregiver to:
/// - Manage notification preferences (placeholder).
/// - Change language (placeholder).
/// - Logout (placeholder).
class CaregiverSettingsScreen extends StatelessWidget {
  const CaregiverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.grey;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: isDark ? Colors.teal.shade700 : Colors.teal,
                child: const Text('CG', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 8),
              Text('Caregiver', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              Text('caregiver@email.com', style: TextStyle(color: subColor)),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),

        const SizedBox(height: 12),

        ListTile(
          leading: Icon(Icons.notifications, color: subColor),
          title: Text('Notifications', style: TextStyle(color: textColor)),
          trailing: Switch(
            value: true, 
            onChanged: (_) {},
            activeColor: Colors.teal,
          ),
        ),
        ListTile(
          leading: Icon(Icons.language, color: subColor),
          title: Text('Language', style: TextStyle(color: textColor)),
          trailing: Text('English', style: TextStyle(color: subColor)),
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
