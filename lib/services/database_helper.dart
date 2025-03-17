import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vcard_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      print('Returning existing database instance');
      return _database!;
    }
    print('Initializing new database instance');
    _database = await _initDB('scanned_contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      print('Getting database path...');
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      print('Database path: $path');

      print('Opening database...');
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
      print('Database opened successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      print('Creating contacts table...');
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
      print('Contacts table created successfully');
    } catch (e) {
      print('Error creating database table: $e');
      rethrow;
    }
  }

  Future<int> insertContact(VCardModel contact) async {
    try {
      print('Inserting contact: ${contact.name}');
      final db = await database;
      final id = await db.insert(
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
      print('Contact inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting contact: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    try {
      print('Getting all contacts...');
      final db = await database;
      final contacts = await db.query(
        'contacts',
        orderBy: 'scanned_at DESC',
      );
      print('Retrieved ${contacts.length} contacts');
      return contacts;
    } catch (e) {
      print('Error getting contacts: $e');
      rethrow;
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      print('Deleting contact with ID: $id');
      final db = await database;
      await db.delete(
        'contacts',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Contact deleted successfully');
    } catch (e) {
      print('Error deleting contact: $e');
      rethrow;
    }
  }

  Future<void> deleteAllContacts() async {
    try {
      print('Deleting all contacts...');
      final db = await database;
      await db.delete('contacts');
      print('All contacts deleted successfully');
    } catch (e) {
      print('Error deleting all contacts: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      print('Closing database...');
      final db = await database;
      db.close();
      print('Database closed successfully');
    } catch (e) {
      print('Error closing database: $e');
      rethrow;
    }
  }
}
