import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../notification_settings_screen.dart';

/// Displays the user's profile and application settings.
/// 
/// Features:
/// - Dark Mode Toggle (managed by [ThemeProvider]).
/// - Navigation to Notification Settings.
/// - Placeholder for Health/Caregiver features.
class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: logic now respects System Mode correctly
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black12 : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // ================= HEADER =================
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'JD',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'john.doe@email.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ================= HEALTH =================
              _sectionHeader('Health', isDark),
              _card(
                isDark: isDark,
                child: _settingsTile(
                  isDark: isDark,
                  icon: Icons.favorite_border,
                  title: 'Caregivers',
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // TODO: Navigate to Caregivers
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ================= SETTINGS =================
              _sectionHeader('Settings', isDark),
              _card(
                isDark: isDark,
                child: Column(
                  children: [
                    _settingsTile(
                      isDark: isDark,
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: isDark ? Colors.grey[800] : null),
                    _settingsTile(
                      isDark: isDark,
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).toggleTheme(val);
                        },
                        activeColor: Colors.teal,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    Divider(height: 1, indent: 56, color: isDark ? Colors.grey[800] : null),
                    _settingsTile(
                      isDark: isDark,
                      icon: Icons.language,
                      title: 'Language',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('English', style: TextStyle(color: Colors.grey)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
