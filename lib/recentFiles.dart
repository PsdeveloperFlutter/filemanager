import 'package:filemanager/fileManageUi.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
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

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        return Container(
          height: 165,
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
                       setIcons(file['type']),
                        const SizedBox(height: 8),
                        Text(
                          file['name'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              IconButton(
                                icon: Icon(Icons.share,
                                    color: Colors.green.shade700),
                                onPressed: () {
                                  Share.shareXFiles([XFile(file['path'])]);
                                },),
                            ],
                          ),
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

  Widget setIcons(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'image':
        return const Icon(Icons.image, color: Colors.blue);
      case 'video':
        return const Icon(Icons.video_library, color: Colors.green);
      case 'directory':
        return const Icon(Icons.folder, color: Colors.orange);
      case 'file':
        return const Icon(Icons.insert_drive_file, color: Colors.blue);
      case 'txt':
        return const Icon(Icons.text_fields, color: Colors.purple);
      case 'audio':
        return const Icon(Icons.audiotrack, color: Colors.pink);
      case 'zip':
        return const Icon(Icons.archive, color: Colors.brown);
      case 'jpg':
        return const Icon(Icons.image, color: Colors.blue);
      default:
        return const Icon(Icons.help_outline, color: Colors.black);
    }
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
