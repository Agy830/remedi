import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/medication.dart';

/// Singleton helper class for SQLite database interactions.
/// 
/// Manages the `medications` and `medication_logs` tables.
/// - `medications`: Stores the schedule and details of the meds.
/// - `medication_logs`: Stores the history of Taken/Missed doses for calendar tracking.
class DBHelper {
  static Database? _database;

  /// Returns the active database connection, initializing it if necessary.
  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  /// Opens the database and creates tables if they don't exist.
  /// 
  /// The schema includes:
  /// 1. `medications`: id, name, dosage, type, time, instructions, isTaken.
  /// 2. `medication_logs`: id, medication_id, taken_at, status (TAKEN/MISSED/SKIPPED).
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'medications.db');
    
    if (kDebugMode) {
      debugPrint('📁 Database path: $path');
    }
    
    return openDatabase(
      path,
      version: 4, // Incremented version for history logs
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await _verifyTableStructure(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('🔄 Creating database tables (version $version)');
    
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        isTaken INTEGER NOT NULL DEFAULT 0,
        startDate TEXT NOT NULL,
        endDate TEXT,
        note TEXT
      )
    ''');

    // History Log Table
    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL, -- ISO8601 DateTime
        status TEXT NOT NULL,   -- 'TAKEN', 'SKIPPED'
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    debugPrint('✅ Database tables created successfully');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN isTaken INTEGER DEFAULT 0');
        debugPrint('✅ Added isTaken column');
      } catch (e) {
         debugPrint('ℹ️ isTaken column might already exist: $e');
      }
    }

    if (oldVersion < 4) {
      // Add medication_logs table
      try {
        await db.execute('''
          CREATE TABLE medication_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            taken_at TEXT NOT NULL,
            status TEXT NOT NULL,
            FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
          )
        ''');
        debugPrint('✅ Created medication_logs table');
      } catch (e) {
        debugPrint('❌ Error creating medication_logs table: $e');
      }
    }
  }

  // ... (verifyTableStructure remains same)

  // ======================
  // LOG CRUD Operations
  // ======================
  Future<int> insertLog(int medId, DateTime takenAt, String status) async {
    final db = await database;
    final id = await db.insert('medication_logs', {
      'medication_id': medId,
      'taken_at': takenAt.toIso8601String(),
      'status': status,
    });
    debugPrint('📝 Logged medication $medId as $status at $takenAt');
    return id;
  }

  Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date) async {
    final db = await database;
    // Query logs for the specific day (start to end of day)
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    return await db.query(
      'medication_logs',
      where: 'taken_at BETWEEN ? AND ?',
      whereArgs: [start, end],
    );
  }
  
  Future<List<Map<String, dynamic>>> getAllLogs() async {
     final db = await database;
     return await db.query('medication_logs');
  }

  // ======================
  // CRUD Operations (rest unchanged)
  // ...


  /* 
  Future<void> _recreateTableWithDefault(Database db) async {
    debugPrint('🔄 Recreating medications table with DEFAULT constraint');
    
    // Create temp table
    await db.execute('''
      CREATE TABLE medications_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        isTaken INTEGER NOT NULL DEFAULT 0,
        startDate TEXT NOT NULL,
        endDate TEXT,
        note TEXT
      )
    ''');
    
    // Copy data
    await db.execute('''
      INSERT INTO medications_temp 
      SELECT id, name, dosage, time, 
             COALESCE(isTaken, 0) as isTaken, 
             startDate, endDate, note 
      FROM medications
    ''');
    
    // Drop old table
    await db.execute('DROP TABLE medications');
    
    // Rename temp table
    await db.execute('ALTER TABLE medications_temp RENAME TO medications');
    
    debugPrint('✅ Table recreated with DEFAULT 0 constraint');
  }
  */

  Future<void> _verifyTableStructure(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(medications)');
      debugPrint('📊 Current medications table structure:');
      for (var column in columns) {
        debugPrint('  ${column['name']} - ${column['type']} - Default: ${column['dflt_value']}');
      }
    } catch (e) {
      debugPrint('❌ Error verifying table structure: $e');
    }
  }

  // ======================
  // CRUD Operations
  // ======================
  Future<int> insertMedication(Medication med) async {
    final db = await database;
    final id = await db.insert('medications', med.toMap());
    debugPrint('✅ Inserted medication: ${med.name} (ID: $id)');
    return id;
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final result = await db.query('medications');

    final today = DateTime.now();

    final medications = result
        .map((e) => Medication.fromMap(e))
        .where((m) {
          final start = m.startDate;
          final end = m.endDate;

          if (today.isBefore(start)) return false;
          if (end != null && today.isAfter(end)) return false;

          return true;
        })
        .toList();
    
    debugPrint('📋 Retrieved ${medications.length} medications from database');
    return medications;
  }

  // ✅ FIXED: Use correct column name 'isTaken'
  Future<void> updateTakenStatus(int medicationId, bool isTaken) async {
    final db = await database;
    
    // First, check if medication exists
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
      limit: 1,
    );
    
    if (result.isEmpty) {
      debugPrint('❌ Medication with ID $medicationId not found');
      return;
    }
    
    // Update the status
    final updated = await db.update(
      'medications',
      {'isTaken': isTaken ? 1 : 0},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    
    if (updated > 0) {
      debugPrint('✅ Updated medication $medicationId: isTaken = $isTaken');
    } else {
      debugPrint('⚠️ No rows updated for medication $medicationId');
    }
  }

  Future<void> resetAllTaken() async {
    final db = await database;
    final updated = await db.update('medications', {'isTaken': 0});
    debugPrint('🔄 Reset $updated medications to not taken');
  }

  // ======================
  // DAILY RESET META
  // ======================
  Future<String?> getLastResetDate() async {
    final db = await database;
    final res = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['last_reset_date'],
      limit: 1,
    );
    return res.isEmpty ? null : res.first['value'] as String?;
  }

  Future<void> setLastResetDate(String date) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'key': 'last_reset_date', 'value': date},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('📅 Set last reset date to: $date');
  }

  // ======================
  // UPDATE MEDICATION (used by Edit screen)
  // ======================
  Future<int> updateMedication(Medication med) async {
    final db = await database;
    final updated = await db.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✏️ Updated medication: ${med.name} (ID: ${med.id})');
    return updated;
  }

  // ======================
  // DELETE MEDICATION (used by MedicationCard)
  // ======================
  Future<void> deleteMedication(int id) async {
    final db = await database;
    await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('🗑️ Deleted medication with ID: $id');
  }

  // ======================
  // DIAGNOSTIC METHODS
  // ======================
  Future<void> debugTableStructure() async {
    final db = await database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(medications)');
    debugPrint('📊 Medications table structure:');
    for (var column in tableInfo) {
      debugPrint('  ${column['name']} - ${column['type']} - Default: ${column['dflt_value']}');
    }
    
    // Also print sample data
    final medications = await db.query('medications', limit: 5);
    debugPrint('📋 Sample data (first 5 rows):');
    for (var med in medications) {
      debugPrint('  ID: ${med['id']}, Name: ${med['name']}, isTaken: ${med['isTaken']}');
    }
  }

  Future<Map<String, dynamic>?> getMedication(int id) async {
    final db = await database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  // In DBHelper class
Future<void> emergencyFixIsTakenColumn() async {
  final db = await database;
  try {
    // Try to add the column if it doesn't exist
    await db.execute('ALTER TABLE medications ADD COLUMN isTaken INTEGER DEFAULT 0');
    debugPrint('✅ Emergency fix: Added isTaken column');
  } catch (e) {
    debugPrint('ℹ️ isTaken column already exists or error: $e');
  }
}


}