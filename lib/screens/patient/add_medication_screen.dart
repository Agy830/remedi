import 'package:flutter/material.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const AddMedicationScreen({super.key, required this.onSaved});
  
  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _noteController = TextEditingController();

  final List<TimeOfDay> _selectedTimes = [];

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.initialize();
      await NotificationService.requestExactAlarmPermission();
    });
  }

  // ---------------- TIME ----------------
  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
        _selectedTimes.sort(
          (a, b) => a.hour == b.hour
              ? a.minute.compareTo(b.minute)
              : a.hour.compareTo(b.hour),
        );
      });
    }
  }

  void _removeTime(int index) {
    setState(() => _selectedTimes.removeAt(index));
  }

  String _formatTimes(List<TimeOfDay> times) {
    return times
        .map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}')
        .join(';');
  }

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
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate() || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();

    final medication = Medication(
      name: name,
      dosage: dosage,
      time: _formatTimes(_selectedTimes),
      startDate: _startDate,
      endDate: _endDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    await DBHelper().insertMedication(medication);

    await NotificationService.scheduleMultipleNotifications(
      times: _selectedTimes
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      title: 'Time to take $name',
      body: 'Dosage: $dosage',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication added successfully')),
    );
    widget.onSaved();

    // IMPORTANT: Do NOT pop (this is a tab)
    _formKey.currentState!.reset();
    _selectedTimes.clear();
    _noteController.clear();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input(
                controller: _nameController,
                label: 'Medication Name',
                icon: Icons.medication,
              ),
              const SizedBox(height: 16),
              _input(
                controller: _dosageController,
                label: 'Dosage',
                icon: Icons.line_weight,
              ),
              const SizedBox(height: 16),

              // ---- TIMES ----
              _sectionTitle('Reminder Times'),
              ..._selectedTimes.asMap().entries.map(
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

              // ---- DATES ----
              _sectionTitle('Schedule'),
              ListTile(
                title: Text('Start Date: ${_startDate.toLocal().toString().split(' ')[0]}'),
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

              // ---- NOTES ----
              _sectionTitle('Notes'),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Optional notes',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
