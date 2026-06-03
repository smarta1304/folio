import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('folio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          documentId INTEGER NOT NULL,
          imagePath TEXT NOT NULL,
          pageOrder INTEGER NOT NULL,
          metadata TEXT,
          FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE folders ADD COLUMN expiresAt TEXT');
      await db.execute('ALTER TABLE pages ADD COLUMN extractedText TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiresAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        pageOrder INTEGER NOT NULL,
        extractedText TEXT,
        metadata TEXT,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // Insert a default "Uncategorized" folder
    await db.insert('folders', {
      'name': 'Uncategorized',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Folder CRUD
  Future<int> insertFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'createdAt DESC');
    return result.map((json) => Folder.fromMap(json)).toList();
  }

  // Document CRUD
  Future<int> insertDocument(Document doc) async {
    final db = await instance.database;
    return await db.insert('documents', doc.toMap());
  }

  Future<List<Document>> getDocumentsByFolder(int folderId) async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      where: 'folderId = ?',
      whereArgs: [folderId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<List<Document>> getRecentDocuments({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await instance.database;
    // Search in document names or page extracted text
    final result = await db.rawQuery('''
      SELECT DISTINCT d.* FROM documents d
      LEFT JOIN pages p ON d.id = p.documentId
      WHERE d.name LIKE ? OR p.extractedText LIKE ?
      ORDER BY d.createdAt DESC
    ''', ['%$query%', '%$query%']);
    
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<List<Folder>> getExpiredFolders() async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'folders',
      where: 'expiresAt IS NOT NULL AND expiresAt < ?',
      whereArgs: [now],
    );
    return result.map((json) => Folder.fromMap(json)).toList();
  }

  Future<int> deleteDocument(int id) async {
    final db = await instance.database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Page CRUD
  Future<int> insertPage(PageModel page) async {
    final db = await instance.database;
    return await db.insert('pages', page.toMap());
  }

  Future<List<PageModel>> getPagesByDocument(int documentId) async {
    final db = await instance.database;
    final result = await db.query(
      'pages',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'pageOrder ASC',
    );
    return result.map((json) => PageModel.fromMap(json)).toList();
  }

  Future<int> updatePage(PageModel page) async {
    final db = await instance.database;
    return await db.update(
      'pages',
      page.toMap(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<int> deletePage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'pages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}