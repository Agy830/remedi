import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'medications.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  time TEXT NOT NULL,
  isTaken INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT,
  note TEXT
)

    ''');
  }

  Future<int> insertMedication(Medication med) async {
    final db = await database;
    return await db.insert('medications', med.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final result = await db.query('medications');
    return result.map((e) => Medication.fromMap(e)).toList();
  }

  Future<int> updateMedication(Medication med) async {
  final db = await database; // your existing getter
  return await db.update(
    'medications',                 // table name
    med.toMap(),                   // map with updated fields
    where: 'id = ?',               // make sure your table has an id column
    whereArgs: [med.id],
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


  Future<void> deleteMedication(int id) async {
    final db = await database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTakenStatus(int id, bool isTaken) async {
  final db = await database;
  await db.update(
    'medications',
    {'isTaken': isTaken ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );
}


Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE medications ADD COLUMN startDate TEXT');
    await db.execute('ALTER TABLE medications ADD COLUMN endDate TEXT');
    await db.execute('ALTER TABLE medications ADD COLUMN note TEXT');
  }
}
}