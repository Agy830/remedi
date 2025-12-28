import 'package:flutter/material.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/widgets/medication_card.dart';

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
    return SafeArea(
      child: Column(
        children: [
          _header(),

          // 🔥 THIS FIXES THE OVERFLOW
          Expanded(
            child: _medications.isEmpty
                ? const Center(child: Text('No medications yet'))
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
          _actionButtons(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
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
  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Patients'),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text('Missed'),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
