import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';

/// Service responsible for syncing local SQLite medications to Supabase
/// so that linked caregivers can monitor adherence.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pushes a single medication update to Supabase.
  /// Typically called after a local SQLite insert or update.
  Future<void> pushMedication(Medication med) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('SyncService: Cannot push medication, no authenticated user.');
        return;
      }

      final data = {
        'patient_id': user.id,
        'local_sqlite_id': med.id,
        'name': med.name,
        'dosage': med.dosage,
        'time': med.time,
        'is_taken': med.isTaken,
        'start_date': med.startDate.toIso8601String(),
        'end_date': med.endDate?.toIso8601String(),
        'note': med.note,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert based on patient_id and local_sqlite_id
      // Since we don't have a unique constraint on (patient_id, local_sqlite_id)
      // we need to first check if it exists or use match.
      
      // Let's check for existing
      final existing = await _supabase
          .from('synced_medications')
          .select('id')
          .eq('patient_id', user.id)
          .eq('local_sqlite_id', med.id!)
          .maybeSingle();

      if (existing != null) {
        // Update
        await _supabase
            .from('synced_medications')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Insert
        await _supabase.from('synced_medications').insert(data);
      }
      
      debugPrint('SyncService: Successfully synced medication ${med.name} (local ID: ${med.id})');
    } catch (e) {
      debugPrint('SyncService: Error syncing medication: $e');
    }
  }

  /// Removes a medication from Supabase when it is deleted locally.
  Future<void> deleteMedication(int localId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('synced_medications')
          .delete()
          .match({
            'patient_id': user.id,
            'local_sqlite_id': localId,
          });
          
      debugPrint('SyncService: Successfully deleted medication (local ID: $localId) from cloud.');
    } catch (e) {
      debugPrint('SyncService: Error deleting medication from cloud: $e');
    }
  }

  /// Syncs the status of all medications, specifically used for the daily reset.
  Future<void> resetAllTakenStatuses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('synced_medications')
          .update({'is_taken': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('patient_id', user.id);
          
      debugPrint('SyncService: Successfully reset cloud taken statuses.');
    } catch (e) {
      debugPrint('SyncService: Error resetting cloud taken statuses: $e');
    }
  }
}
