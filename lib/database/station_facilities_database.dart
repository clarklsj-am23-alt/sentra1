import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StationFacilitiesDatabase {
  static final StationFacilitiesDatabase instance =
  StationFacilitiesDatabase._init();

  static Database? _database;

  StationFacilitiesDatabase._init();

  // Get database
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // Create database file
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'station_facilities.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  // Create table
  Future<void> _createDatabase(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE station_facilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_name TEXT NOT NULL,
        facility_type TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // Add facility
  Future<int> addFacility({
    required String stationName,
    required String facilityType,
    required String location,
    required String status,
  }) async {
    final db = await database;

    return await db.insert(
      'station_facilities',
      {
        'station_name': stationName,
        'facility_type': facilityType,
        'location': location,
        'status': status,
      },
    );
  }

  // Get all facilities
  Future<List<Map<String, dynamic>>> getFacilities() async {
    final db = await database;

    return await db.query(
      'station_facilities',
      orderBy: 'station_name ASC',
    );
  }

  // Delete facility
  Future<int> deleteFacility(int id) async {
    final db = await database;

    return await db.delete(
      'station_facilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}