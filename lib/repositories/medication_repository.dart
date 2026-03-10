import '../models/medication.dart';
import '../database/db_helper.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAllMedications();
  Future<int> insertMedication(Medication medication);
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(int id);
  Future<void> updateTakenStatus(int id, bool isTaken);

  
  // History Logs
  Future<void> logMedication(int medId, DateTime takenAt, String status);
  Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date);
  Future<List<Map<String, dynamic>>> getAllLogs();
}

class SqliteMedicationRepository implements MedicationRepository {
  final DBHelper _dbHelper;

  SqliteMedicationRepository(this._dbHelper);

  @override
  Future<List<Medication>> getAllMedications() {
    return _dbHelper.getAllMedications();
  }

  @override
  Future<int> insertMedication(Medication medication) {
    return _dbHelper.insertMedication(medication);
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    await _dbHelper.updateMedication(medication);
  }

  @override
  Future<void> deleteMedication(int id) async {
    await _dbHelper.deleteMedication(id);
  }

  @override
  Future<void> updateTakenStatus(int id, bool isTaken) async {
    await _dbHelper.updateTakenStatus(id, isTaken);
  }

  @override
  Future<void> logMedication(int medId, DateTime takenAt, String status) async {
    await _dbHelper.insertLog(medId, takenAt, status);
  }
  
  @override
  Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date) {
    return _dbHelper.getLogsForDate(date);
  }
  
  @override
  Future<List<Map<String, dynamic>>> getAllLogs() {
    return _dbHelper.getAllLogs();
  }
}
