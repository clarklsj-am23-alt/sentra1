import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class StationFacilitiesDatabase {
  static final StationFacilitiesDatabase instance =
  StationFacilitiesDatabase._init();

  static Database? _database;

  StationFacilitiesDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'station_facilities.db',
    );

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

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
        status TEXT NOT NULL,
        accessibility_note TEXT DEFAULT '',
        is_step_free INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _seedFacilities(db);
  }

  Future<void> _upgradeDatabase(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE station_facilities "
            "ADD COLUMN accessibility_note TEXT DEFAULT ''",
      );

      await db.execute(
        "ALTER TABLE station_facilities "
            "ADD COLUMN is_step_free INTEGER NOT NULL DEFAULT 0",
      );

      await _seedFacilities(db);
    }
  }

  // Prototype/demo offline station data.
  // Later your team can replace these with verified station information.
  Future<void> _seedFacilities(Database db) async {
    final demoFacilities = [
      {
        'station_name': 'KL Sentral',
        'facility_type': 'Lift',
        'location': 'Main Concourse',
        'status': 'Available',
        'accessibility_note': 'Suitable for wheelchair users',
        'is_step_free': 1,
      },
      {
        'station_name': 'KL Sentral',
        'facility_type': 'OKU Toilet',
        'location': 'Main Concourse',
        'status': 'Available',
        'accessibility_note': 'Accessible toilet facility',
        'is_step_free': 1,
      },
      {
        'station_name': 'KL Sentral',
        'facility_type': 'Accessible Gate',
        'location': 'Fare Gate Area',
        'status': 'Available',
        'accessibility_note': 'Wide gate for wheelchair access',
        'is_step_free': 1,
      },
      {
        'station_name': 'Pasar Seni',
        'facility_type': 'Lift',
        'location': 'Station Entrance',
        'status': 'Available',
        'accessibility_note': 'Step-free access to station level',
        'is_step_free': 1,
      },
      {
        'station_name': 'Pasar Seni',
        'facility_type': 'Tactile Paving',
        'location': 'Platform Area',
        'status': 'Available',
        'accessibility_note': 'Guiding path for visually impaired users',
        'is_step_free': 1,
      },
      {
        'station_name': 'Bukit Bintang',
        'facility_type': 'Escalator',
        'location': 'Station Entrance',
        'status': 'Available',
        'accessibility_note': 'Escalator access between levels',
        'is_step_free': 0,
      },
      {
        'station_name': 'Bukit Bintang',
        'facility_type': 'Lift',
        'location': 'Concourse Area',
        'status': 'Available',
        'accessibility_note': 'Wheelchair accessible',
        'is_step_free': 1,
      },
      {
        'station_name': 'Muzium Negara',
        'facility_type': 'Ramp',
        'location': 'Station Entrance',
        'status': 'Available',
        'accessibility_note': 'Ramp for wheelchair access',
        'is_step_free': 1,
      },
      {
        'station_name': 'Muzium Negara',
        'facility_type': 'Tactile Paving',
        'location': 'Concourse and Platform',
        'status': 'Available',
        'accessibility_note': 'Guidance path for visually impaired users',
        'is_step_free': 1,
      },
    ];

    for (final facility in demoFacilities) {
      final existing = await db.query(
        'station_facilities',
        where:
        'station_name = ? AND facility_type = ? AND location = ?',
        whereArgs: [
          facility['station_name'],
          facility['facility_type'],
          facility['location'],
        ],
      );

      if (existing.isEmpty) {
        await db.insert(
          'station_facilities',
          facility,
        );
      }
    }
  }

  // CREATE
  Future<int> addFacility({
    required String stationName,
    required String facilityType,
    required String location,
    required String status,
    String accessibilityNote = '',
    bool isStepFree = false,
  }) async {
    final db = await database;

    return await db.insert(
      'station_facilities',
      {
        'station_name': stationName,
        'facility_type': facilityType,
        'location': location,
        'status': status,
        'accessibility_note': accessibilityNote,
        'is_step_free': isStepFree ? 1 : 0,
      },
    );
  }

  // READ + SEARCH + FILTER
  Future<List<Map<String, dynamic>>> getFacilities({
    String search = '',
    String facilityType = 'All',
    bool stepFreeOnly = false,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <Object?>[];

    if (search.trim().isNotEmpty) {
      conditions.add(
        '(station_name LIKE ? OR '
            'facility_type LIKE ? OR '
            'location LIKE ?)',
      );

      final query = '%${search.trim()}%';

      arguments.addAll([
        query,
        query,
        query,
      ]);
    }

    if (facilityType != 'All') {
      conditions.add('facility_type = ?');
      arguments.add(facilityType);
    }

    if (stepFreeOnly) {
      conditions.add('is_step_free = 1');
    }

    return await db.query(
      'station_facilities',
      where: conditions.isEmpty
          ? null
          : conditions.join(' AND '),
      whereArgs: arguments.isEmpty
          ? null
          : arguments,
      orderBy: 'station_name ASC, facility_type ASC',
    );
  }

  // UPDATE
  Future<int> updateFacility({
    required int id,
    required String stationName,
    required String facilityType,
    required String location,
    required String status,
    String accessibilityNote = '',
    bool isStepFree = false,
  }) async {
    final db = await database;

    return await db.update(
      'station_facilities',
      {
        'station_name': stationName,
        'facility_type': facilityType,
        'location': location,
        'status': status,
        'accessibility_note': accessibilityNote,
        'is_step_free': isStepFree ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteFacility(int id) async {
    final db = await database;

    return await db.delete(
      'station_facilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}