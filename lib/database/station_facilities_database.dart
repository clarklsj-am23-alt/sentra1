import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StationFacilitiesDatabase {
  static final StationFacilitiesDatabase instance =
  StationFacilitiesDatabase._init();

  static Database? _database;

  StationFacilitiesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'station_facilities.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE station_facilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_name TEXT NOT NULL,
        facility_type TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Seed default sample facilities
    final batch = db.batch();
    final sampleData = [
      {'station_name': 'KL Sentral', 'facility_type': 'Elevator / Lift', 'location': 'Platform 1 to Concourse', 'status': 'Operational'},
      {'station_name': 'KL Sentral', 'facility_type': 'Wheelchair Ramp', 'location': 'Main Entrance Gate A', 'status': 'Operational'},
      {'station_name': 'KL Sentral', 'facility_type': 'Accessible Toilet', 'location': 'Level 1 near Surau', 'status': 'Operational'},
      {'station_name': 'Pasar Seni', 'facility_type': 'Elevator / Lift', 'location': 'LRT to MRT Linkway', 'status': 'Under Maintenance'},
      {'station_name': 'Pasar Seni', 'facility_type': 'Tactile Paving', 'location': 'Platform 2 edge', 'status': 'Operational'},
      {'station_name': 'Bukit Bintang', 'facility_type': 'Elevator / Lift', 'location': 'Exit D (Lot 10)', 'status': 'Operational'},
      {'station_name': 'Bukit Bintang', 'facility_type': 'Accessible Gate', 'location': 'Faregate line B', 'status': 'Operational'},
    ];

    for (var item in sampleData) {
      batch.insert('station_facilities', item);
    }
    await batch.commit(noResult: true);
  }

  Future<int> addFacility({
    required String stationName,
    required String facilityType,
    required String location,
    required String status,
  }) async {
    final db = await database;
    return await db.insert('station_facilities', {
      'station_name': stationName,
      'facility_type': facilityType,
      'location': location,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getFacilities() async {
    final db = await database;
    return await db.query('station_facilities', orderBy: 'station_name ASC');
  }

  Future<List<Map<String, dynamic>>> getFacilitiesByStation(String stationName) async {
    final db = await database;
    return await db.query(
      'station_facilities',
      where: 'station_name = ?',
      whereArgs: [stationName],
      orderBy: 'facility_type ASC',
    );
  }

  Future<int> updateFacility({
    required int id,
    required String stationName,
    required String facilityType,
    required String location,
    required String status,
  }) async {
    final db = await database;
    return await db.update(
      'station_facilities',
      {
        'station_name': stationName,
        'facility_type': facilityType,
        'location': location,
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFacility(int id) async {
    final db = await database;
    return await db.delete(
      'station_facilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}