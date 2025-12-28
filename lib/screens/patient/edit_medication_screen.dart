import 'package:flutter/material.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/services/notification_service.dart';

class EditMedicationScreen extends StatefulWidget {
  final Medication medication;

  const EditMedicationScreen({
    super.key,
    required this.medication,
  });

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameC;
  late final TextEditingController _dosageC;
  late final TextEditingController _noteC;

  final db = DBHelper();
  List<TimeOfDay> _reminderTimes = [];

  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    _nameC = TextEditingController(text: widget.medication.name);
    _dosageC = TextEditingController(text: widget.medication.dosage);
    _noteC = TextEditingController(text: widget.medication.note ?? '');

    _startDate = widget.medication.startDate;
    _endDate = widget.medication.endDate;

    if (widget.medication.time.isNotEmpty) {
      _reminderTimes = _parseTimes(widget.medication.time);
    }
  }

  // ---------------- TIME ----------------
  List<TimeOfDay> _parseTimes(String value) {
    return value.split(';').map((t) {
      final p = t.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }).toList();
  }

  String _formatTimes(List<TimeOfDay> times) {
    return times
        .map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}')
        .join(';');
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _reminderTimes.add(picked);
        _reminderTimes.sort(
          (a, b) => a.hour == b.hour
              ? a.minute.compareTo(b.minute)
              : a.hour.compareTo(b.hour),
        );
      });
    }
  }

  void _removeTime(int i) => setState(() => _reminderTimes.removeAt(i));

  // ---------------- DATE ----------------
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ---------------- SAVE ----------------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.medication.copyWith(
      name: _nameC.text.trim(),
      dosage: _dosageC.text.trim(),
      time: _formatTimes(_reminderTimes),
      startDate: _startDate,
      endDate: _endDate,
      note: _noteC.text.trim().isEmpty ? null : _noteC.text.trim(),
      isTaken: false, // reset for edited schedule
    );

    await db.updateMedication(updated);

    // Cancel old notifications
    await NotificationService.cancelNotification(widget.medication.id!);

    // Reschedule notifications
    await NotificationService.scheduleMultipleNotifications(
      times: _reminderTimes
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      title: 'Time to take ${updated.name}',
      body: 'Dosage: ${updated.dosage}',
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _dosageC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medication'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input(_nameC, 'Medication Name', Icons.medication),
              const SizedBox(height: 16),
              _input(_dosageC, 'Dosage', Icons.line_weight),
              const SizedBox(height: 16),

              _section('Reminder Times'),
              ..._reminderTimes.asMap().entries.map(
                (e) => ListTile(
                  title: Text(e.value.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTime(e.key),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add),
                label: const Text('Add Time'),
              ),

              const SizedBox(height: 24),
              _section('Schedule'),
              ListTile(
                title: Text(
                  'Start Date: ${_startDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickStartDate,
              ),
              ListTile(
                title: Text(
                  _endDate == null
                      ? 'End Date: Not set'
                      : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickEndDate,
              ),

              const SizedBox(height: 24),
              _section('Notes'),
              TextFormField(
                controller: _noteC,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Optional notes',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Update Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: c,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
}
