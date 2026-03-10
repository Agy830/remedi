import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/medication.dart';

class CaregiverPatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String relationship;

  const CaregiverPatientDetailScreen({
    super.key,
    required this.patientData,
    required this.relationship,
  });

  @override
  State<CaregiverPatientDetailScreen> createState() =>
      _CaregiverPatientDetailScreenState();
}

class _CaregiverPatientDetailScreenState extends State<CaregiverPatientDetailScreen> {
  bool _isLoading = true;
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _fetchPatientMedications();
  }

  Future<void> _fetchPatientMedications() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patientData['id'];
      if (patientId == null) throw Exception("Patient ID is null");

      // Query the synced_medications table for this patient
      final response = await Supabase.instance.client
          .from('synced_medications')
          .select()
          .eq('patient_id', patientId)
          .order('time', ascending: true);

      final List<Medication> meds = [];
      for (var row in response) {
        // Map the Supabase row back to our Medication model
        // We use the local_sqlite_id as the ID since that's what the UI expects for keys/colors
        final med = Medication(
          id: row['local_sqlite_id'] as int,
          name: row['name'] as String,
          dosage: row['dosage'] as String,
          time: row['time'] as String,
          isTaken: row['is_taken'] as bool,
          startDate: DateTime.parse(row['start_date']),
          endDate: row['end_date'] != null ? DateTime.parse(row['end_date']) : null,
          note: row['note'] as String?,
        );
        meds.add(med);
      }

      if (mounted) {
        setState(() {
          _medications = meds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = '${widget.patientData['firstname'] ?? ''} ${widget.patientData['lastname'] ?? ''}'.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName.isEmpty ? 'Unknown Patient' : patientName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: isDark ? Colors.black26 : Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.person, size: 40, color: Colors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    patientName.isEmpty ? 'Unknown Patient' : patientName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Relationship: ${widget.relationship}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                     'Patient ID: ${widget.patientData['id'] ?? 'N/A'}',
                     style: const TextStyle(fontSize: 12, color: Colors.grey)
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Patient has no active medications.',
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchPatientMedications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _medications.length,
                            itemBuilder: (context, index) {
                              final med = _medications[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: med.isTaken ? Colors.green.shade200 : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: med.isTaken ? Colors.green.shade100 : Colors.blue.shade100,
                                    child: Icon(
                                      med.isTaken ? Icons.check : Icons.medication,
                                      color: med.isTaken ? Colors.green : Colors.blue,
                                    ),
                                  ),
                                  title: Text(
                                    med.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('${med.dosage} at ${med.time}'),
                                      if (med.note != null && med.note!.isNotEmpty)
                                        Text('Note: ${med.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                  trailing: med.isTaken
                                      ? const Chip(
                                          label: Text('Taken', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          backgroundColor: Colors.green,
                                        )
                                      : const Chip(
                                          label: Text('Pending', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          backgroundColor: Colors.orange,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
