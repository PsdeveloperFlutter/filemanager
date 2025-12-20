import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  /// Singleton
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const String tableName = 'students';
  Database? _db;

  /// Get Database Instance
  Future<Database> getDB() async {
    _db ??= await _openDB();
    return _db!;
  }

  /// Open Database
  Future<Database> _openDB() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'students_Database.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $tableName(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          rollno INTEGER,
          age INTEGER,
          className TEXT,
          email TEXT,
          phone TEXT,
          photo TEXT
        )
        ''');
      },
    );
  }

  /// Insert Data (Photo Optional)
  Future<int> insertData({
    required String name,
    required int rollno,
    required int age,
    required String className,
    required String email,
    required String phone,
    String? photo,
  }) async {
    try {
      final db = await getDB();
      return await db.insert(tableName, {
        'name': name,
        'rollno': rollno,
        'age': age,
        'className': className,
        'email': email,
        'phone': phone,
        'photo': photo, // can be null
      });
    } catch (e) {
      throw Exception('Insert Data Failed: $e');
    }
  }

  /// Delete Data
  Future<int> deleteData(int id) async {
    final db = await getDB();
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  ///Fetch Data from Table
  Future<List<Map<String, Object?>>>fetchData()async{
    Database db=await getDB();
    return await db.query(tableName);
  }
}
