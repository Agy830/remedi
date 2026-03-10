import 'package:flutter/material.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:remedi/models/medication.dart';
import 'package:remedi/widgets/medication_card.dart';
import 'package:remedi/database/db_remote_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../patient/caregiver_patient_detail_screen.dart';

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
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final patients = await DbRemoteHelper().getCaregiverPatients(currentUserId);
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
    }
  }

  // Calculate overall adherence (mocked for now, pending a patient-specific medication query)
  double get _adherence {
    if (_patients.isEmpty) return 0;
    return 0.85; // Placeholder 85%
  }

  void _showAddPatientDialog() {
    final patientIdController = TextEditingController();
    final relationshipController = TextEditingController();
    bool canEdit = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Link Patient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the Patient ID provided by the patient.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: relationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship (e.g., Son, Nurse)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Can edit medications?'),
                    value: canEdit,
                    onChanged: (val) {
                      setStateDialog(() => canEdit = val ?? false);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (patientIdController.text.trim().isEmpty) return;
                    
                    try {
                      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                      await DbRemoteHelper().linkPatientToCaregiver(
                        patientId: patientIdController.text.trim(),
                        caregiverId: currentUserId,
                        relationship: relationshipController.text.trim(),
                        canEditMedications: canEdit,
                      );
                      
                      if (context.mounted) {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Patient linked successfully!')),
                         );
                         _loadPatients(); 
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Error linking: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Link Patient'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Link a Patient',
            onPressed: _showAddPatientDialog,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _header(isDark),

          // 🔥 PATIENT LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? Center(
                        child: Text(
                          'No patients linked yet.\nUse the + button to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _patients.length,
                        itemBuilder: (_, i) {
                          final linkRecord = _patients[i];
                          final patientData = linkRecord['patients'] as Map<String, dynamic>?;
                          final patientName = patientData != null
                              ? '${patientData['firstname'] ?? ''} ${patientData['lastname'] ?? ''}'.trim()
                              : 'Unknown Patient';
                          final relationship = linkRecord['relationship'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(Icons.person, color: Colors.teal),
                              ),
                              title: Text(
                                patientName.isEmpty ? 'Unknown Patient' : patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text('Relationship: $relationship'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                if (patientData != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CaregiverPatientDetailScreen(
                                        patientData: patientData,
                                        relationship: relationship,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),

          // ✅ TEMP BUTTONS (for explanation & future features)
          _actionButtons(isDark),
        ],
      ),
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
