import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vcard_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanned_contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        website TEXT,
        title TEXT,
        address TEXT,
        scanned_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertContact(VCardModel contact) async {
    final db = await database;
    return await db.insert(
      'contacts',
      {
        'name': contact.name,
        'company': contact.company,
        'email': contact.email,
        'phone': contact.phone,
        'website': contact.website,
        'title': contact.title,
        'address': contact.address,
        'scanned_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final db = await database;
    return await db.query(
      'contacts',
      orderBy: 'scanned_at DESC',
    );
  }

  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllContacts() async {
    final db = await database;
    await db.delete('contacts');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
