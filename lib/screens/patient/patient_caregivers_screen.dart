import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/db_remote_helper.dart';

class PatientCaregiversScreen extends StatefulWidget {
  const PatientCaregiversScreen({super.key});

  @override
  State<PatientCaregiversScreen> createState() =>
      _PatientCaregiversScreenState();
}

class _PatientCaregiversScreenState extends State<PatientCaregiversScreen> {
  List<Map<String, dynamic>> _caregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final data = await DbRemoteHelper().getPatientCaregivers(currentUserId);
      if (mounted) {
        setState(() {
          _caregivers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading caregivers: $e')),
        );
      }
    }
  }

  Future<void> _removeCaregiver(String caregiverId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access?'),
        content: const Text(
          'Are you sure you want to remove this caregiver? They will no longer be able to see your medications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      await DbRemoteHelper().unlinkCaregiver(
        patientId: currentUserId,
        caregiverId: caregiverId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caregiver access revoked.')),
        );
        _loadCaregivers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing caregiver: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Caregivers'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _caregivers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No caregivers linked.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To give someone access, provide them with your Patient ID from your Profile page.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _caregivers.length,
                    itemBuilder: (_, i) {
                      final linkRecord = _caregivers[i];
                      final caregiverData = linkRecord['caregivers'] as Map<String, dynamic>?;
                      final caregiverName = caregiverData != null
                          ? '${caregiverData['firstname'] ?? ''} ${caregiverData['lastname'] ?? ''}'.trim()
                          : 'Unknown Caregiver';
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
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.favorite, color: Colors.blue),
                          ),
                          title: Text(
                            caregiverName.isEmpty ? 'Unknown Caregiver' : caregiverName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text('Relationship: $relationship'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Revoke Access',
                            onPressed: () {
                              if (caregiverData != null && caregiverData['id'] != null) {
                                _removeCaregiver(caregiverData['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
