import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transit_card_model.dart';

class CardDatabaseService {
  static final CardDatabaseService instance = CardDatabaseService._init();
  static Database? _database;

  CardDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transit_cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transit_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_name TEXT NOT NULL,
            card_number TEXT NOT NULL,
            balance REAL NOT NULL,
            card_type TEXT NOT NULL
          )
        ''');

        await db.insert('transit_cards', {
          'card_name': 'My Touch \'n Go',
          'card_number': '1088 2938 1029',
          'balance': 35.50,
          'card_type': 'OKU Concession',
        });
      },
    );
  }

  Future<List<TransitCard>> getAllCards() async {
    final db = await database;
    final result = await db.query('transit_cards', orderBy: 'id DESC');
    return result.map((json) => TransitCard.fromMap(json)).toList();
  }

  Future<int> insertCard(TransitCard card) async {
    final db = await database;
    return await db.insert('transit_cards', card.toMap());
  }

  Future<int> updateBalance(int id, double newBalance) async {
    final db = await database;
    return await db.update(
      'transit_cards',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(
      'transit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}