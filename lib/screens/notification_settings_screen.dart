import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:remedi/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String _selectedSound = 'default';
  bool _persistentAlarm = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final sound = await NotificationService.getSoundPreference();
    final persistent = await NotificationService.getPersistentPreference();
    setState(() {
      _selectedSound = sound;
      _persistentAlarm = persistent;
    });
  }

  Future<void> _saveSound(String? value) async {
    if (value == null) return;
    await NotificationService.setSoundPreference(value);
    setState(() => _selectedSound = value);
    
    // Reschedule to apply new sound
    await NotificationService.rescheduleAllNotifications();
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sound updated & alarms rescheduled')),
      );
    }
  }

  Future<void> _savePersistent(bool value) async {
    await NotificationService.setPersistentPreference(value);
    setState(() => _persistentAlarm = value);
    
    // Reschedule to apply new behavior
    await NotificationService.rescheduleAllNotifications();
  }

  Future<void> _playSound() async {
    try {
      // Map key to asset file
      String fileName = 'notification.mp3';
      if (_selectedSound == 'loud') fileName = 'alarm_loud.mp3';
      if (_selectedSound == 'soft') fileName = 'alarm_soft.mp3';
      if (_selectedSound == 'long') fileName = 'alarm_long.mp3';

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not play preview: $e')));
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black12 : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: isDark ? Colors.black : Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sound Preference',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Alert Sound',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedSound,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: _saveSound,
                    items: [
                      DropdownMenuItem(
                        value: 'default', 
                        child: Text('Default', style: TextStyle(color: isDark ? Colors.white : Colors.black87))
                      ),
                      DropdownMenuItem(
                        value: 'loud', 
                        child: Text('Loud Alarm', style: TextStyle(color: isDark ? Colors.white : Colors.black87))
                      ),
                      DropdownMenuItem(
                        value: 'soft', 
                        child: Text('Soft Chime', style: TextStyle(color: isDark ? Colors.white : Colors.black87))
                      ),
                      DropdownMenuItem(
                        value: 'long', 
                        child: Text('Long Melody', style: TextStyle(color: isDark ? Colors.white : Colors.black87))
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? Colors.grey[800] : null),
                ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.teal),
                  title: Text(
                    'Preview Sound',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: _playSound,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Behavior',
             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey),
          ),
           const SizedBox(height: 10),
           Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
               border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
            ),
            child: SwitchListTile(
              title: Text(
                'Persistent Alarm',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                'Keep ringing until taken',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              value: _persistentAlarm,
              activeColor: Colors.teal,
              onChanged: _savePersistent,
            ),
           ),
        ],
      ),
    );
  }
}
