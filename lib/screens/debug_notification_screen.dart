import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../database/db_helper.dart';
import '../models/medication.dart'; // Add this import

class DebugNotificationScreen extends StatefulWidget {
  const DebugNotificationScreen({super.key}); // Add key parameter

  @override
  _DebugNotificationScreenState createState() => _DebugNotificationScreenState();
}

class _DebugNotificationScreenState extends State<DebugNotificationScreen> {
  List<Medication> medications = []; // Change type to List<Medication>

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final dbHelper = DBHelper();
    final meds = await dbHelper.getAllMedications();
    setState(() {
      medications = meds;
    });
  }

  Future<void> _testNotificationAction(int medicationId, String action) async {
    debugPrint('🧪 Testing $action for medication $medicationId');
    
    if (action == 'taken') {
      await DBHelper().updateTakenStatus(medicationId, true);
    } else if (action == 'snooze') {
      // You'll need to call the internal method
      // For now, just update the UI
      debugPrint('Snooze would be called for $medicationId');
    }
    
    await _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Debug'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Use the debug method we added
              NotificationService.debugPrintNotificationInfo();
              _loadMedications();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Service Status', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.debugPrintNotificationInfo();
                    },
                    child: Text('Print Debug Info'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Medications in Database', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...medications.map((medication) {
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(medication.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${medication.id}'),
                    Text('Taken: ${medication.isTaken ? 'Yes' : 'No'}'),
                    Text('Snooze Count: ${NotificationService.getSnoozeCount(medication.id!)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _testNotificationAction(medication.id!, 'taken'),
                    ),
                    IconButton(
                      icon: Icon(Icons.snooze, color: Colors.orange),
                      onPressed: () => _testNotificationAction(medication.id!, 'snooze'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}