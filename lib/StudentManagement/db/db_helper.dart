import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  /// Singleton
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  static const String studentTable = 'students';
  static const String attendanceTable = 'attendance';

  Database? _db;

  /// ================= DATABASE =================

  Future<Database> getDB() async {
    _db ??= await _openDB();
    return _db!;
  }

  Future<Database> _openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'student_database.db');

    return openDatabase(
      path,
      version: 5, // ⬅️ IMPORTANT
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ================= CREATE TABLES =================

  Future<void> _onCreate(Database db, int version) async {
    /// Students table
    await db.execute('''
      CREATE TABLE $studentTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        rollno INTEGER,
        age INTEGER,
        className TEXT,
        email TEXT,
        phone TEXT,
        photo TEXT,
        description TEXT
      )
    ''');

    /// Attendance table (FINAL VERSION)
    await db.execute('''
      CREATE TABLE $attendanceTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        date TEXT,
        isPresent INTEGER
      )
    ''');

    ///Holiday Table
    await db.execute('''
    CREATE TABLE holidays(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT
    )
    ''');
  }

  /// ================= DATABASE MIGRATION =================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Old versions support
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $studentTable ADD COLUMN description TEXT',
      );
    }

    // status ➜ isPresent migration (OPTION 2)
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE attendance_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          studentId INTEGER,
          date TEXT,
          isPresent INTEGER
        )
      ''');

      // Copy old data (status ➜ isPresent)
      await db.execute('''
        INSERT INTO attendance_new (id, studentId, date, isPresent)
        SELECT id, studentId, date, status FROM $attendanceTable
      ''');

      await db.execute('DROP TABLE $attendanceTable');

      await db.execute(
        'ALTER TABLE attendance_new RENAME TO $attendanceTable',
      );
    }
    if (oldVersion < 5) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS holidays(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      reason TEXT
    )
  ''');
    }
  }

  /// ================= STUDENT CRUD =================

  Future<int> insertStudent({
    required String name,
    required int rollno,
    required int age,
    required String className,
    required String email,
    required String phone,
    String? photo,
    String? description,
  }) async {
    final db = await getDB();
    return db.insert(studentTable, {
      'name': name,
      'rollno': rollno,
      'age': age,
      'className': className,
      'email': email,
      'phone': phone,
      'photo': photo,
      'description': description,
    });
  }

  Future<List<Map<String, Object?>>> fetchStudents() async {
    final db = await getDB();
    return db.query(studentTable);
  }

  Future<int> deleteStudent(int id) async {
    final db = await getDB();
    return db.delete(
      studentTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateStudent({
    required int id,
    required String name,
    required int rollno,
    required int age,
    required String className,
    required String email,
    required String phone,
    String? photo,
    String? description,
  }) async {
    final db = await getDB();
    return db.update(
      studentTable,
      {
        'name': name,
        'rollno': rollno,
        'age': age,
        'className': className,
        'email': email,
        'phone': phone,
        'photo': photo,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ================= ATTENDANCE =================

  /// Mark / Update attendance
  Future<int> markAttendance({
    required int studentId,
    required String date,
    required bool isPresent,
  }) async {
    final db = await getDB();

    final existing = await db.query(
      attendanceTable,
      where: 'studentId = ? AND date = ?',
      whereArgs: [studentId, date],
    );

    if (existing.isNotEmpty) {
      return db.update(
        attendanceTable,
        {'isPresent': isPresent ? 1 : 0},
        where: 'studentId = ? AND date = ?',
        whereArgs: [studentId, date],
      );
    } else {
      return db.insert(attendanceTable, {
        'studentId': studentId,
        'date': date,
        'isPresent': isPresent ? 1 : 0,
      });
    }
  }

  /// Fetch attendance by student
  Future<List<Map<String, Object?>>> fetchAttendance(int studentId) async {
    final db = await getDB();
    return db.query(
      attendanceTable,
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
  }

  /// Fetch attendance by date
  Future<List<Map<String, Object?>>> fetchAttendanceByDate(String date) async {
    final db = await getDB();
    return db.query(
      attendanceTable,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  /// Delete attendance
  Future<int> deleteAttendance(int id) async {
    final db = await getDB();
    return db.delete(
      attendanceTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Monthly summary
  Future<Map<String, int>> monthlySummary(
      int studentId, int month, int year) async {
    final db = await getDB();

    final result = await db.rawQuery('''
      SELECT isPresent, COUNT(*) as total
      FROM $attendanceTable
      WHERE studentId = ?
      AND strftime('%m', date) = ?
      AND strftime('%Y', date) = ?
      GROUP BY isPresent
    ''', [
      studentId,
      month.toString().padLeft(2, '0'),
      year.toString(),
    ]);

    int present = 0, absent = 0;

    for (var row in result) {
      if (row['isPresent'] == 1) present = row['total'] as int;
      if (row['isPresent'] == 0) absent = row['total'] as int;
    }

    return {'present': present, 'absent': absent};
  }

  /// ================= MONTHLY ATTENDANCE SUMMARY =================
  Future<Map<String, dynamic>> getMonthlyAttendanceSummary({
    required int studentId,
    required int month,
    required int year,
  }) async {
    final db = await getDB();

    /// Month start & end
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = DateTime(year, month + 1, 0);

    int totalDays = endDate.day;

    /// Count Sundays
    int sundayCount = 0;
    for (int i = 0; i < totalDays; i++) {
      DateTime date = startDate.add(Duration(days: i));
      if (date.weekday == DateTime.sunday) {
        sundayCount++;
      }
    }

    /// Count Present Days
    final presentResult = await db.rawQuery('''
    SELECT COUNT(*) as present
    FROM attendance
    WHERE studentId = ?
    AND isPresent = 1
    AND date BETWEEN ? AND ?
  ''', [studentId, startDate.toIso8601String(), endDate.toIso8601String()]);

    int presentDays = Sqflite.firstIntValue(presentResult) ?? 0;

    /// Count Custom Holidays
    final holidayResult = await db.rawQuery('''
    SELECT COUNT(*) as total
    FROM holidays
    WHERE date BETWEEN ? AND ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    int holidayCount = Sqflite.firstIntValue(holidayResult) ?? 0;

    /// Working days calculation
    int workingDays = totalDays - (sundayCount + holidayCount);

    /// Count Absent Days from DB
    final absentResult = await db.rawQuery('''
    SELECT COUNT(*) as absent
    FROM $attendanceTable
    WHERE studentId = ?
    AND isPresent = 0
    AND date BETWEEN ? AND ?
  ''', [studentId, startDate.toIso8601String(), endDate.toIso8601String()]);

    int absentDays = Sqflite.firstIntValue(absentResult) ?? 0;

    double percentage =
        workingDays == 0 ? 0 : (presentDays / workingDays) * 100;

    ///Return summary map From Database to Attendance Summary Screen
    return {
      'totalDays': totalDays,
      'sundays': sundayCount,
      'holidays': holidayCount,
      'workingDays': workingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'percentage': percentage.toStringAsFixed(2),
    };
  }

  ///-------------------------------- INSERT HOLIDAY  -------------------------------
  Future<int> addHoliday({
    required String date,
    required String reason,
  }) async {
    final db = await getDB();
    return await db.insert('holidays', {
      'date': date,
      'reason': reason,
    });
  }

  //-------------------------------- GET HOLIDAY  -------------------------------//
  Future<List<Map<String, dynamic>>> getHolidays() async {
    final db = await getDB();
    return db.query('holidays');
  }

  //-------------------------------- DELETE HOLIDAY  -------------------------------//
  Future<bool> deleteHolidays(int id) async {
    final db = await getDB();
    final count = await db.delete('holidays', where: 'id=?', whereArgs: [id]);
    return count > 0;
  }
}
