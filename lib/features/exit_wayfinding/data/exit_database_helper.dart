import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ExitDatabaseHelper {
  ExitDatabaseHelper._();

  static final ExitDatabaseHelper instance = ExitDatabaseHelper._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      join(directory, 'sentra1_exits.db'),
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
    _database = database;
    return database;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lines TEXT NOT NULL,
        source_name TEXT NOT NULL,
        source_url TEXT NOT NULL,
        source_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE station_exits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id TEXT NOT NULL,
        exit_code TEXT NOT NULL,
        destination TEXT NOT NULL,
        bearing_degrees REAL NOT NULL,
        is_step_free INTEGER NOT NULL,
        bearing_note TEXT NOT NULL,
        verified_date TEXT NOT NULL,
        FOREIGN KEY (station_id) REFERENCES stations (id)
      )
    ''');

    final batch = db.batch();
    batch.insert('stations', {
      'id': 'kl_sentral',
      'name': 'KL Sentral',
      'lines': 'LRT Kelana Jaya|KTM Komuter|MRT Kajang',
      'source_name': 'data.gov.my public transport dataset',
      'source_url': 'https://data.gov.my/data-catalogue/ridership_headline',
      'source_date': '2026-07-31',
    });
    batch.insert('stations', {
      'id': 'pasar_seni',
      'name': 'Pasar Seni',
      'lines': 'LRT Kelana Jaya|MRT Kajang',
      'source_name': 'data.gov.my public transport dataset',
      'source_url': 'https://data.gov.my/data-catalogue/ridership_headline',
      'source_date': '2026-07-31',
    });
    batch.insert('station_exits', {
      'station_id': 'kl_sentral',
      'exit_code': 'Exit A',
      'destination': 'Jalan Tun Sambanthan (Brickfields)',
      'bearing_degrees': 90.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'kl_sentral',
      'exit_code': 'Exit B',
      'destination': 'Jalan Travers / Nu Sentral',
      'bearing_degrees': 270.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'pasar_seni',
      'exit_code': 'Exit A',
      'destination': 'Jalan Sultan (Chinatown)',
      'bearing_degrees': 45.0,
      'is_step_free': 0,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'pasar_seni',
      'exit_code': 'Exit B',
      'destination': 'Dayabumi Complex and Bus Hub',
      'bearing_degrees': 210.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    await batch.commit(noResult: true);
    await _seedAdditionalStations(db);
    await _seedMoreStations(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _seedAdditionalStations(db);
    if (oldVersion < 3) await _seedMoreStations(db);
    if (oldVersion < 4) await _seedMaluri(db);
  }

  Future<void> _seedAdditionalStations(Database db) async {
    final batch = db.batch();
    batch.insert('stations', {
      'id': 'masjid_jamek',
      'name': 'Masjid Jamek',
      'lines': 'LRT Kelana Jaya|LRT Ampang',
      'source_name': 'data.gov.my public transport dataset',
      'source_url': 'https://data.gov.my/data-catalogue/ridership_headline',
      'source_date': '2026-07-31',
    });
    batch.insert('stations', {
      'id': 'bukit_bintang',
      'name': 'Bukit Bintang',
      'lines': 'MRT Kajang|KL Monorail',
      'source_name': 'data.gov.my public transport dataset',
      'source_url': 'https://data.gov.my/data-catalogue/ridership_headline',
      'source_date': '2026-07-31',
    });
    batch.insert('stations', {
      'id': 'titiwangsa',
      'name': 'Titiwangsa',
      'lines': 'LRT Ampang|KL Monorail|MRT Putrajaya',
      'source_name': 'data.gov.my public transport dataset',
      'source_url': 'https://data.gov.my/data-catalogue/ridership_headline',
      'source_date': '2026-07-31',
    });
    batch.insert('station_exits', {
      'station_id': 'masjid_jamek',
      'exit_code': 'Exit A',
      'destination': 'Jalan Tun Perak',
      'bearing_degrees': 180.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'masjid_jamek',
      'exit_code': 'Exit B',
      'destination': 'Central Market',
      'bearing_degrees': 270.0,
      'is_step_free': 0,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'bukit_bintang',
      'exit_code': 'Exit A',
      'destination': 'Jalan Bukit Bintang',
      'bearing_degrees': 90.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'bukit_bintang',
      'exit_code': 'Exit B',
      'destination': 'Pavilion Kuala Lumpur',
      'bearing_degrees': 0.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'titiwangsa',
      'exit_code': 'Exit A',
      'destination': 'Hospital Kuala Lumpur',
      'bearing_degrees': 45.0,
      'is_step_free': 1,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    batch.insert('station_exits', {
      'station_id': 'titiwangsa',
      'exit_code': 'Exit B',
      'destination': 'Jalan Tun Razak',
      'bearing_degrees': 225.0,
      'is_step_free': 0,
      'bearing_note': 'Approximate app metadata; follow station signage.',
      'verified_date': '2026-09-01',
    });
    await batch.commit(noResult: true);
  }

  Future<void> _seedMoreStations(Database db) async {
    const sourceName = 'data.gov.my public transport dataset';
    const sourceUrl = 'https://data.gov.my/data-catalogue/ridership_headline';
    const sourceDate = '2026-07-31';
    const verifiedDate = '2026-09-01';
    const bearingNote = 'Approximate app metadata; follow station signage.';
    final batch = db.batch();
    for (final station in [
      {
        'id': 'muzium_negara',
        'name': 'Muzium Negara',
        'lines': 'MRT Kajang',
        'source_name': sourceName,
        'source_url': sourceUrl,
        'source_date': sourceDate,
      },
      {
        'id': 'merdeka',
        'name': 'Merdeka',
        'lines': 'MRT Kajang',
        'source_name': sourceName,
        'source_url': sourceUrl,
        'source_date': sourceDate,
      },
      {
        'id': 'cochrane',
        'name': 'Cochrane',
        'lines': 'MRT Kajang',
        'source_name': sourceName,
        'source_url': sourceUrl,
        'source_date': sourceDate,
      },
      {
        'id': 'bandar_utama',
        'name': 'Bandar Utama',
        'lines': 'MRT Kajang',
        'source_name': sourceName,
        'source_url': sourceUrl,
        'source_date': sourceDate,
      },
      {
        'id': 'tun_razak_exchange',
        'name': 'Tun Razak Exchange',
        'lines': 'MRT Kajang|MRT Putrajaya',
        'source_name': sourceName,
        'source_url': sourceUrl,
        'source_date': sourceDate,
      },
    ]) {
      batch.insert('stations', station);
    }
    for (final exit in [
      {
        'station_id': 'muzium_negara',
        'exit_code': 'Exit A',
        'destination': 'Muzium Negara',
        'bearing_degrees': 0.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'muzium_negara',
        'exit_code': 'Exit B',
        'destination': 'KL Sentral Link',
        'bearing_degrees': 180.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'merdeka',
        'exit_code': 'Exit A',
        'destination': 'Jalan Hang Jebat',
        'bearing_degrees': 90.0,
        'is_step_free': 0,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'merdeka',
        'exit_code': 'Exit B',
        'destination': 'Stadium Merdeka',
        'bearing_degrees': 270.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'cochrane',
        'exit_code': 'Exit A',
        'destination': 'MyTOWN Shopping Centre',
        'bearing_degrees': 45.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'cochrane',
        'exit_code': 'Exit B',
        'destination': 'Jalan Cochrane',
        'bearing_degrees': 225.0,
        'is_step_free': 0,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'bandar_utama',
        'exit_code': 'Exit A',
        'destination': '1 Utama Shopping Centre',
        'bearing_degrees': 90.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'bandar_utama',
        'exit_code': 'Exit B',
        'destination': 'Persiaran Bandar Utama',
        'bearing_degrees': 270.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'tun_razak_exchange',
        'exit_code': 'Exit A',
        'destination': 'The Exchange TRX',
        'bearing_degrees': 45.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
      {
        'station_id': 'tun_razak_exchange',
        'exit_code': 'Exit B',
        'destination': 'Jalan Tun Razak',
        'bearing_degrees': 225.0,
        'is_step_free': 1,
        'bearing_note': bearingNote,
        'verified_date': verifiedDate,
      },
    ]) {
      batch.insert('station_exits', exit);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedMaluri(Database db) async {
    const sourceName = 'data.gov.my public transport dataset';
    const sourceUrl = 'https://data.gov.my/data-catalogue/ridership_headline';
    const sourceDate = '2026-07-31';
    const verifiedDate = '2026-09-01';
    const bearingNote = 'Approximate app metadata; follow station signage.';
    final batch = db.batch();
    batch.insert('stations', {
      'id': 'maluri',
      'name': 'Maluri',
      'lines': 'MRT Kajang|LRT Ampang',
      'source_name': sourceName,
      'source_url': sourceUrl,
      'source_date': sourceDate,
    });
    batch.insert('station_exits', {
      'station_id': 'maluri',
      'exit_code': 'Exit A',
      'destination': 'Sunway Velocity Mall',
      'bearing_degrees': 90.0,
      'is_step_free': 1,
      'bearing_note': bearingNote,
      'verified_date': verifiedDate,
    });
    batch.insert('station_exits', {
      'station_id': 'maluri',
      'exit_code': 'Exit B',
      'destination': 'Jalan Jejaka',
      'bearing_degrees': 270.0,
      'is_step_free': 1,
      'bearing_note': bearingNote,
      'verified_date': verifiedDate,
    });
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, Object?>>> getStations() async {
    final db = await database;
    return db.query('stations', orderBy: 'name ASC');
  }

  Future<List<Map<String, Object?>>> getExitsByStation(String stationId) async {
    final db = await database;
    return db.query(
      'station_exits',
      where: 'station_id = ?',
      whereArgs: [stationId],
      orderBy: 'exit_code ASC',
    );
  }
}
