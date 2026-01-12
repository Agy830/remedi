import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/medication.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'medications.db');
    
    if (kDebugMode) {
      debugPrint('📁 Database path: $path');
    }
    
    return openDatabase(
      path,
      version: 3, // Incremented version for migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // Verify table structure on open
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
        isTaken INTEGER NOT NULL DEFAULT 0,  -- ✅ Changed to DEFAULT 0
        startDate TEXT NOT NULL,
        endDate TEXT,
        note TEXT
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
        // Check if isTaken column has DEFAULT 0
        final columns = await db.rawQuery('PRAGMA table_info(medications)');
        final isTakenColumn = columns.firstWhere(
          (col) => col['name'] == 'isTaken',
          orElse: () => {},
        );
        
        if (isTakenColumn.isEmpty) {
          debugPrint('⚠️ isTaken column not found, adding it...');
          await db.execute('ALTER TABLE medications ADD COLUMN isTaken INTEGER DEFAULT 0');
        } else if (isTakenColumn['dflt_value'] == null) {
          debugPrint('🔄 Adding DEFAULT 0 to isTaken column');
          // We need to recreate the table to add DEFAULT constraint
          await _recreateTableWithDefault(db);
        }
      } catch (e) {
        debugPrint('❌ Error during migration: $e');
      }
    }
  }

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