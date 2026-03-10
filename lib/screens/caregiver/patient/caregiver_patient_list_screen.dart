import 'package:flutter/material.dart';
import '../../../models/medication.dart';

class CaregiverPatientListScreen extends StatelessWidget {
  final List<Medication> medications;

  const CaregiverPatientListScreen({
    super.key,
    required this.medications,
  });

  String _formatTime(String time) {
    // Handles multiple times like "18:11;20:29"
    return time.split(';').map((t) {
      final parts = t.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      final isPM = hour >= 12;
      final displayHour = hour == 0
          ? 12
          : hour > 12
              ? hour - 12
              : hour;

      return '$displayHour:$minute ${isPM ? 'PM' : 'AM'}';
    }).join(', ');
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No medications available')),
      );
    }

    return Column(
      children: medications.map((med) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor:
                  med.isTaken ? Colors.green : Colors.grey.shade400,
              child: const Icon(Icons.medication, color: Colors.white),
            ),
            title: Text(
              med.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Dosage: ${med.dosage}'),
                Text(
                  'Time: ${_formatTime(med.time)}',
                  style: const TextStyle(fontSize: 12),
                ),

                if (med.note != null && med.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${med.note}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'From ${_formatDate(med.startDate)}'
                    '${med.endDate != null ? ' → ${_formatDate(med.endDate!)}' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Icon(
              med.isTaken ? Icons.check_circle : Icons.schedule,
              color: med.isTaken ? Colors.green : Colors.orange,
            ),
          ),
        );
      }).toList(),
    );
  }
}
