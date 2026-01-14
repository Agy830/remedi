import 'package:flutter/material.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/widgets/medication_card.dart';

/// The main dashboard for the Caregiver view.
/// 
/// Displays an overview of the patient's adherence:
/// - A header with today's adherence percentage.
/// - A list of all medications (read-only view).
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final meds = await DBHelper().getAllMedications();
    if (mounted) setState(() => _medications = meds);
  }

  double get _adherence {
    if (_medications.isEmpty) return 0;
    final taken = _medications.where((m) => m.isTaken).length;
    return taken / _medications.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          _header(isDark),

          // 🔥 THIS FIXES THE OVERFLOW
          Expanded(
            child: _medications.isEmpty
                ? Center(
                    child: Text(
                      'No medications yet',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _medications.length,
                    itemBuilder: (_, i) {
                      return MedicationCard(
                        medication: _medications[i],
                        readOnly: true,
                      );
                    },
                  ),
          ),

          // ✅ TEMP BUTTONS (for explanation & future features)
          _actionButtons(isDark),
        ],
      ),
    );
  }

  Widget _header(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.teal,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caregiver Dashboard',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_adherence * 100).toStringAsFixed(0)}% adherence today',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// TEMP BUTTONS (DO NOT REMOVE YET)
  /// 
  /// These serve as placeholders for future navigation to:
  /// - Patient List (for multi-patient support)
  /// - Missed Doses Report
  Widget _actionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.people, color: isDark ? Colors.white70 : Colors.teal),
              label: Text('Patients', style: TextStyle(color: isDark ? Colors.white70 : Colors.teal)),
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                 side: BorderSide(color: isDark ? Colors.white24 : Colors.teal.shade100),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.warning, color: isDark ? Colors.orangeAccent : Colors.orange),
              label: Text('Missed', style: TextStyle(color: isDark ? Colors.orangeAccent : Colors.orange)),
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                 side: BorderSide(color: isDark ? Colors.white24 : Colors.orange.shade100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
