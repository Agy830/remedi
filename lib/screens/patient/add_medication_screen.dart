import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/services/notification_service.dart';
import '../../providers/providers.dart';

/// Screen for adding a new medication.
/// 
/// Handles:
/// - Form validation (Name, Dosage).
/// - Multiple reminder time selection.
/// - Scheduling notifications upon save.
class AddMedicationScreen extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const AddMedicationScreen({super.key, required this.onSaved});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
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

  // ================= TIME =================
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

  // ================= DATE =================
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

  // ================= SAVE =================
  Future<void> _saveMedication() async {
    // 🔐 FORCE notification permission
    final allowed =
        await NotificationService.requestNotificationPermission();

    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable notifications to set medication reminders',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final medication = Medication(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      time: _formatTimes(_selectedTimes),
      startDate: _startDate,
      endDate: _endDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
        // Direct repository use to get ID for notification scheduling
        // (Controller refactor to return ID involves changing generated code signature too much for this hotfix)
        final repository = ref.read(medicationRepositoryProvider);
        final medicationId = await repository.insertMedication(medication);
        
        // Invalidate provider to update UI
        ref.invalidate(activeMedicationsProvider);

        // Schedule Notifications
        // We calculate all selected times and schedule an alarm for each.
        await NotificationService.scheduleMultipleNotifications(
          medicationId: medicationId,
          times: _selectedTimes
              .map((t) => {'hour': t.hour, 'minute': t.minute})
              .toList(),
          title: 'Time to take ${medication.name}',
          body: 'Dosage: ${medication.dosage}',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added successfully')),
        );

        widget.onSaved();

        // RESET FORM (tab-safe)
        _formKey.currentState!.reset();
        _selectedTimes.clear();
        _noteController.clear();
        
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error adding medication: $e')),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? null : Colors.white,
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
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _input(
                controller: _dosageController,
                label: 'Dosage',
                icon: Icons.line_weight,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _sectionTitle('Reminder Times', isDark),
              ..._selectedTimes.asMap().entries.map(
                (e) => ListTile(
                  title: Text(
                    e.value.format(context),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
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

              _sectionTitle('Schedule', isDark),
              ListTile(
                title: Text(
                  'Start Date: ${_startDate.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                trailing: Icon(Icons.calendar_today, color: isDark ? Colors.white70 : Colors.black54),
                onTap: _pickStartDate,
              ),
              ListTile(
                title: Text(
                  _endDate == null
                      ? 'End Date: Not set'
                      : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                trailing: Icon(Icons.calendar_today, color: isDark ? Colors.white70 : Colors.black54),
                onTap: _pickEndDate,
              ),

              const SizedBox(height: 24),

              _sectionTitle('Notes', isDark),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Optional notes',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey),
                  ),
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
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]), // Explicit color for visibility
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

