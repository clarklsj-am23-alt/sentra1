import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transit_card_model.dart';

class CardTransaction {
  final int? id;
  final int cardId;
  final String title;
  final double amount;
  final String type; // 'TOP_UP' or 'FARE'
  final String date;

  CardTransaction({
    this.id,
    required this.cardId,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }

  factory CardTransaction.fromMap(Map<String, dynamic> map) {
    return CardTransaction(
      id: map['id'] as int?,
      cardId: map['card_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: map['date'] as String,
    );
  }
}

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
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS card_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              card_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              type TEXT NOT NULL,
              date TEXT NOT NULL,
              FOREIGN KEY (card_id) REFERENCES transit_cards (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE transit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        card_number TEXT NOT NULL,
        balance REAL NOT NULL,
        card_type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE card_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES transit_cards (id) ON DELETE CASCADE
      )
    ''');

    final cardId = await db.insert('transit_cards', {
      'card_name': 'My Touch \'n Go',
      'card_number': '1088 2938 1029',
      'balance': 35.50,
      'card_type': 'OKU Concession',
    });

    await db.insert('card_transactions', {
      'card_id': cardId,
      'title': 'Initial Top Up',
      'amount': 35.50,
      'type': 'TOP_UP',
      'date': DateTime.now().toString().substring(0, 16),
    });
  }

  Future<List<TransitCard>> getAllCards() async {
    final db = await database;
    final result = await db.query('transit_cards', orderBy: 'id DESC');
    return result.map((json) => TransitCard.fromMap(json)).toList();
  }

  Future<int> insertCard(TransitCard card) async {
    final db = await database;
    final cardId = await db.insert('transit_cards', card.toMap());
    if (card.balance > 0) {
      await logTransaction(
        cardId: cardId,
        title: 'Initial Balance',
        amount: card.balance,
        type: 'TOP_UP',
      );
    }
    return cardId;
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

  Future<int> logTransaction({
    required int cardId,
    required String title,
    required double amount,
    required String type,
  }) async {
    final db = await database;
    return await db.insert('card_transactions', {
      'card_id': cardId,
      'title': title,
      'amount': amount,
      'type': type,
      'date': DateTime.now().toString().substring(0, 16),
    });
  }

  Future<List<CardTransaction>> getTransactionsByCard(int cardId) async {
    final db = await database;
    try {
      final result = await db.query(
        'card_transactions',
        where: 'card_id = ?',
        whereArgs: [cardId],
        orderBy: 'id DESC',
      );
      return result.map((json) => CardTransaction.fromMap(json)).toList();
    } catch (e) {
      // Create table if the database is running on an older local schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS card_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          card_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (card_id) REFERENCES transit_cards (id) ON DELETE CASCADE
        )
      ''');
      return [];
    }
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    await db.delete('card_transactions', where: 'card_id = ?', whereArgs: [id]);
    return await db.delete('transit_cards', where: 'id = ?', whereArgs: [id]);
  }
}