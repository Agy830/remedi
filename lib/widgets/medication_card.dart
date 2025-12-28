import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/medication.dart';
import '../screens/patient/edit_medication_screen.dart';
import '../services/notification_service.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;

  /// Called after edit / delete / toggle
  final VoidCallback? onUpdated;

  /// true = caregiver (no edit/delete/toggle)
  final bool readOnly;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onUpdated,
    this.readOnly = false,
  });

  Future<void> _toggleTaken(BuildContext context) async {
    if (readOnly || medication.id == null) return;

    await DBHelper()
        .updateTakenStatus(medication.id!, !medication.isTaken);

    onUpdated?.call();
  }

  Future<void> _delete(BuildContext context) async {
    if (readOnly || medication.id == null) return;

    await DBHelper().deleteMedication(medication.id!);
    await NotificationService.cancelNotification(medication.id!);

    onUpdated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medication.name} deleted')),
    );
  }

  Future<void> _edit(BuildContext context) async {
    if (readOnly) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(medication: medication),
      ),
    );

    if (result == true) {
      onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(medication.id.toString()),
      direction:
          readOnly ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: readOnly
          ? null
          : (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Medication'),
                  content: Text(
                    'Are you sure you want to delete ${medication.name}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
      onDismissed: readOnly ? null : (_) => _delete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
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
                medication.isTaken ? Colors.green : Colors.teal,
            child: const Icon(Icons.medication, color: Colors.white),
          ),

          title: Text(
            medication.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: medication.isTaken
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Dosage: ${medication.dosage}'),
              Text(
                'Time: ${medication.time.replaceAll(';', ', ')}',
                style: const TextStyle(fontSize: 12),
              ),

              if (medication.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    medication.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),

              if (medication.endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Ends: ${medication.endDate!.day}/${medication.endDate!.month}/${medication.endDate!.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ),
            ],
          ),

          trailing: readOnly
              ? Icon(
                  medication.isTaken
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: medication.isTaken
                      ? Colors.green
                      : Colors.orange,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _edit(context),
                    ),
                    Checkbox(
                      value: medication.isTaken,
                      onChanged: (_) => _toggleTaken(context),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
