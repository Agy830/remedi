import 'package:flutter/material.dart';
import 'package:remedi/services/notification_service.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  String _sound = 'default';
  bool _persistent = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await NotificationService.getSoundPreference();
    final p = await NotificationService.getPersistentPreference();
    setState(() {
      _sound = s;
      _persistent = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Persistent Alarm'),
            subtitle: const Text('Loop sound until action is taken'),
            value: _persistent,
            onChanged: (val) async {
              await NotificationService.setPersistentPreference(val);
              setState(() => _persistent = val);
            },
          ),
          ListTile(
            title: const Text('Notification Sound'),
            subtitle: Text(NotificationService.soundNames[_sound] ?? 'Default'),
            trailing: DropdownButton<String>(
              value: _sound,
              items: NotificationService.soundNames.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  await NotificationService.setSoundPreference(val);
                  setState(() => _sound = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
