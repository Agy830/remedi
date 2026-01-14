import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remedi/services/notification_service.dart';
import '../../database/db_helper.dart';
import '../../models/medication.dart';
import '../../widgets/medication_card.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with WidgetsBindingObserver {
  List<Medication> _medications = [];
  
  // Add a StreamController for real-time updates
  final _refreshController = StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    
    // Listen for refresh events
    _refreshController.stream.listen((_) {
      debugPrint('🔄 Received refresh signal');
      _loadMedications();
    });

    // In PatientHomeScreen initState, after _init():
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dbHelper = DBHelper();
      await dbHelper.emergencyFixIsTakenColumn();
    });
  }

  Future<void> _init() async {
    await _resetTakenIfNewDay();
    await _checkMissedDoses(); // Check for missed meds on load
    await _loadMedications();
  }
  
  /// Checks for any missed doses since the app was last opened.
  /// 
  /// Logic:
  /// 1. Get all medications scheduled for today.
  /// 2. If a medication is NOT taken and the scheduled time was > 1 minute ago (Testing Mode),
  ///    we consider it "Missed".
  /// 3. We log an entry in the `medication_logs` table with status 'MISSED'.
  /// 
  /// This ensures that the Calendar history accurately reflects missed medications.
  Future<void> _checkMissedDoses() async {
    // Only run this check once per app start/resume to avoid spamming logs
    
    final meds = await DBHelper().getAllMedications();
    final logs = await DBHelper().getLogsForDate(DateTime.now());
    final now = DateTime.now();
    
    for (var med in meds) {
      if (!med.isTaken) {
         final parts = med.time.split(':');
         final scheduledTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
         
         // If time passed by > 1 minute (FOR TESTING ONLY, WAS > 60)
         if (now.difference(scheduledTime).inMinutes > 1) {
           
           // Check if we already logged a "MISSED" status for this med today
           final alreadyLogged = logs.any((log) => 
               log['medication_id'] == med.id && 
               (log['status'] == 'MISSED' || log['status'] == 'TAKEN')
           );

           if (!alreadyLogged) {
             debugPrint('⚠️ Found missed dose for ${med.name}, logging failure...');
             await DBHelper().insertLog(med.id!, DateTime.now(), 'MISSED');
           }
         }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('📱 AppLifecycleState changed: $state');
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed, handling pending actions...');
      try {
        await NotificationService.handlePendingAction();
        debugPrint('✅ Pending actions handled');
        
        // Trigger refresh after handling actions
        _refreshController.add(null);
        
      } catch (e) {
        debugPrint('❌ Error handling pending actions: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMedications();
  }

  @override
  void didUpdateWidget(covariant PatientHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMedications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.close();
    super.dispose();
  }

  Future<void> _resetTakenIfNewDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = await DBHelper().getLastResetDate();

    if (lastDate != today) {
      debugPrint('📅 New day detected, resetting taken status...');
      await DBHelper().resetAllTaken();
      await DBHelper().setLastResetDate(today);
      debugPrint('✅ Taken status reset for new day');
    }
  }

  Future<void> _loadMedications() async {
    try {
      final meds = await DBHelper().getAllMedications();
      if (!mounted) return;
      
      setState(() => _medications = meds);
      
      // Debug: print medication status
      for (var med in meds) {
        final snoozeCount = NotificationService.getSnoozeCount(med.id!);
        debugPrint('💊 ${med.name}: ID=${med.id}, Taken=${med.isTaken}, Snoozes=$snoozeCount');
      }
    } catch (e) {
      debugPrint('❌ Error loading medications: $e');
    }
  }

/*
  // Add test methods
  Future<void> _testScheduleNotification() async {
    if (_medications.isEmpty) {
      debugPrint('❌ No medications to test');
      return;
    }
    
    final medication = _medications.first;
    debugPrint('🧪 Scheduling test notification for: ${medication.name}');
    
    // Schedule for 10 seconds from now
    final testTime = DateTime.now().add(Duration(seconds: 10));
    
    await NotificationService.scheduleNotification(
      id: medication.id!,
      hour: testTime.hour,
      minute: testTime.minute,
      title: 'TEST: ${medication.name}',
      body: 'Test notification - check Taken/Snooze actions',
    );
    
    debugPrint('✅ Test notification scheduled for ${testTime.hour}:${testTime.minute}');
    debugPrint('⚠️ Notification will appear in 10 seconds');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test notification scheduled in 10 seconds')),
    );
  }

  Future<void> _forceRefresh() async {
    debugPrint('🔄 Manual refresh triggered');
    await _loadMedications();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refreshed medications')),
    );
  }
*/

  double get _progress {
    if (_medications.isEmpty) return 0;
    final taken = _medications.where((m) => m.isTaken).length;
    return taken / _medications.length;
  }

/*
  // Add this to PatientHomeScreen class
Future<void> _diagnoseMedication(int medicationId) async {
  final dbHelper = DBHelper();
  
  // 1. Get raw data from database
  final rawData = await dbHelper.getMedication(medicationId);
  if (rawData != null) {
    debugPrint('🔍 RAW DATABASE DATA for ID $medicationId:');
    rawData.forEach((key, value) {
      debugPrint('  $key: $value (type: ${value.runtimeType})');
    });
    
    // Check specifically for isTaken
    if (rawData.containsKey('isTaken')) {
      debugPrint('✅ isTaken column exists with value: ${rawData['isTaken']}');
    } else {
      debugPrint('❌ isTaken column DOES NOT exist in database!');
    }
  } else {
    debugPrint('❌ No medication found with ID $medicationId');
  }
  
  // 2. Try to update
  debugPrint('\n🔄 Testing updateTakenStatus...');
  try {
    await dbHelper.updateTakenStatus(medicationId, true);
    debugPrint('✅ updateTakenStatus executed');
    
    // Check again after update
    final updatedData = await dbHelper.getMedication(medicationId);
    debugPrint('🔄 After update - isTaken: ${updatedData?['isTaken']}');
  } catch (e) {
    debugPrint('❌ Error updating: $e');
  }
}
*/

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        // Enhanced debug panel
        if (_medications.isNotEmpty) /* _debugPanel() */ SizedBox(),
        Expanded(
          child: _medications.isEmpty
              ? const Center(
                  child: Text(
                    'No medications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadMedications();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _medications.length,
                    itemBuilder: (_, i) {
                      return MedicationCard(
                        medication: _medications[i],
                        onUpdated: () {
                          _refreshController.add(null);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

/*
  Widget _debugPanel() {
    return Card(
      margin: EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧪 Debug Panel', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Notification Service Status:', style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Text('Snooze working: ✅', style: TextStyle(color: Colors.green)),
            Text('Last action: SNOOZE_10 for ID 1', style: TextStyle(fontSize: 11)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ElevatedButton(
                  onPressed: _testScheduleNotification,
                  child: Text('Test Notif'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_medications.isNotEmpty) {
                      final med = _medications.first;
                      await DBHelper().updateTakenStatus(med.id!, true);
                      NotificationService.resetSnoozeCount(med.id!);
                      _refreshController.add(null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked ${med.name} as taken manually')),
                      );
                    }
                  },
                  child: Text('Mark Taken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: _forceRefresh,
                  child: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    NotificationService.debugPrintNotificationInfo();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Debug info printed to console')),
                    );
                  },
                  child: Text('Debug Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 36),
                  ),
                ),
                ElevatedButton(
  onPressed: () async {
    final dbHelper = DBHelper();
    await dbHelper.debugTableStructure();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Table structure printed to console')),
    );
  },
  child: Text('Check DB'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.brown,
    foregroundColor: Colors.white,
  ),
),
// Add this button to your _debugPanel() Wrap widget:
ElevatedButton(
  onPressed: () async {
    if (_medications.isNotEmpty) {
      final med = _medications.first;
      await _diagnoseMedication(med.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagnosed ${med.name}')),
      );
    }
  },
  child: Text('Diagnose'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
  ),
),
              ],
            ),
          ],
        ),
      ),
    );
  }
*/

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hello 👋', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          const Text(
            "Here's your medication schedule",
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
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% taken today',
            style: const TextStyle(color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            '${_medications.where((m) => m.isTaken).length}/${_medications.length} medications taken',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}