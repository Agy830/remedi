import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/medication.dart';
import '../../widgets/medication_card.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final meds = await DBHelper().getAllMedications();
    if (!mounted) return;
    setState(() => _medications = meds);
  }

  double get _progress {
    if (_medications.isEmpty) return 0;
    final taken = _medications.where((m) => m.isTaken).length;
    return taken / _medications.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),

        Expanded(
          child: _medications.isEmpty
              ? const Center(
                  child: Text(
                    'No medications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _medications.length,
                  itemBuilder: (_, i) {
                    return MedicationCard(
                      medication: _medications[i],
                      onUpdated: _loadMedications,
                    );
                  },
                ),
        ),
      ],
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
          const Text('Hello 👋', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          const Text(
            "Here’s your medication schedule",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% taken today',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
