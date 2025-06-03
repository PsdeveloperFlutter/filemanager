import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class RecentDbHelper {
  static final RecentDbHelper _instance = RecentDbHelper._internal();

  factory RecentDbHelper() => _instance;

  RecentDbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recent_files.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recent_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            path TEXT UNIQUE,
            type TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertOrUpdate(Map<String, dynamic> file) async {
    final db = await database;
    try {
      await db.insert('recent_files', file,
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("File inserted or updated successfully");
    } on DatabaseException catch (e) {
      print('Error inserting or updating file: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentFiles() async {
    final db = await database;
    return await db.query('recent_files', orderBy: 'id DESC');
  }

  Future<void> deleteRecentFile(String path) async {
    final db = await database;
    await db.delete('recent_files', where: 'path = ?', whereArgs: [path]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('recent_files');
  }
}

//This is the UI logic of the Recent files

class RecentFilesScreen extends StatefulWidget {
  const RecentFilesScreen({Key? key}) : super(key: key);
  @override
  State<RecentFilesScreen> createState() => RecentFilesScreenState();
}

class RecentFilesScreenState extends State<RecentFilesScreen> {
  late Future<void> _initFuture;
  List<Map<String, dynamic>> recentFiles = [];
  bool _isSelectionMode = false; // Controls the appearance of checkboxes
  List<String> _selectedFiles = []; // Tracks selected files

  @override
  void initState() {
    super.initState();
    _initFuture = _loadRecentFilesOnce();
  }

  Future<void> _loadRecentFilesOnce() async {
    final files = await RecentDbHelper().getRecentFiles();
    recentFiles = files;
  }

  Future<void> insertFile(Map<String, dynamic> file) async {
    await RecentDbHelper().insertOrUpdate(file);
    setState(() {
      _initFuture = _loadRecentFilesOnce();
    });
  }

  Future<void> _deleteFile(String path) async {
    await RecentDbHelper().deleteRecentFile(path);
    setState(() {
      recentFiles = List<Map<String, dynamic>>.from(recentFiles);
      recentFiles.removeWhere((f) => f['path'] == path);
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFiles.clear(); // Clear selection when exiting selection mode
      }
    });
  }

  void _toggleFileSelection(String path) {
    setState(() {
      if (_selectedFiles.contains(path)) {
        _selectedFiles.remove(path);
      } else {
        _selectedFiles.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        return GestureDetector(
          onLongPress: (){
            _toggleSelectionMode();// This will toggle the selection mode when a long press is detected
          },
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentFiles.length,
            itemBuilder: (context, index) {
              final file = recentFiles[index];
              return SingleChildScrollView(
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          file['type'] == 'directory'
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          size: 50,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          file['name'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSelectionMode == false)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteFile(file['path']);
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.open_in_new,
                                  color: Colors.blue.shade700),
                              onPressed: () {
                                openFileWithIntent(file['path'], context);
                              },
                            ),
                            if (_isSelectionMode)
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.share,
                                  color: Colors.green,
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

//This function opens a file using the OpenFilex package and shows a snackbar if it fails
Future<void> openFileWithIntent(String filePath, BuildContext context) async {
  final result = await OpenFilex.open(filePath);
  if (result.type != ResultType.done) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to open file: ${result.message}')),
    );
  }
}
