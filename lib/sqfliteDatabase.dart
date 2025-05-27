import 'dart:io';

import 'package:filemanager/fileBrowserController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FavoriteDBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT UNIQUE
          )
        ''');
      },
    );
  }

  Future<void> addFavorite(String path) async {
    try {
      final db = await database;
      await db.insert('favorites', {'path': path},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text("Added to favorites")),
      );
    } catch (e) {
      print("Error adding favorite: $e");
    }
  }

  Future<void> removeFavorite(String path) async {
    final db = await database;
    await db.delete('favorites', where: 'path = ?', whereArgs: [path]);
  }

  Future<List<String>> getFavorites() async {
    final db = await database;
    final result = await db.query('favorites');
    return result.map((row) => row['path'] as String).toList();
  }

  Future<bool> isFavorite(String path) async {
    final db = await database;
    final result =
        await db.query('favorites', where: 'path = ?', whereArgs: [path]);
    return result.isNotEmpty;
  }
}

class FavoriteScreen extends StatefulWidget {
  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final dbHelper = FavoriteDBHelper();
  final fileController = Get.put(FileBrowserController());

  List<String> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites(); // Load DB once
  }

  // Load favorites from database
  Future<void> loadFavorites() async {
    favorites = await dbHelper.getFavorites();
    setState(() {
      isLoading = false;
    });
  }

  // Delete from list and database, without reloading entire DB
  void deleteFavorite(String path) async {
    await dbHelper.removeFavorite(path);
    favorites.remove(path); // Remove from local list only
    setState(() {});
    Get.snackbar("Deleted", "Removed from favorites");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Favorite Files & Folders")),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : favorites.isEmpty
                ? Center(child: Text("No favorites found"))
                : fileController.isGridView.value
                    ? GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final path = favorites[index];
                          final entity = FileSystemEntity.typeSync(path) ==
                                  FileSystemEntityType.directory
                              ? Directory(path)
                              : File(path);
                          return Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    entity is Directory
                                        ? Icons.folder
                                        : Icons.insert_drive_file,
                                    color: Colors.blue.shade700),
                                SizedBox(height: 8),
                                Text(path.split('/').last),
                                SizedBox(height: 8),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => deleteFavorite(path),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final path = favorites[index];
                          final entity = FileSystemEntity.typeSync(path) ==
                                  FileSystemEntityType.directory
                              ? Directory(path)
                              : File(path);

                          return Dismissible(
                            key: Key(path),
                            // Unique key
                            direction: DismissDirection.endToStart,
                            // Swipe from right to left
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              deleteFavorite(path); // Delete from list and DB
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Deleted from favorites')),
                              );
                            },
                            child: ListTile(
                              onTap: () {
                                if (entity is Directory) {
                                  fileController.openDirectory(entity, context);
                                } else {
                                  fileController.openFile(entity, context);
                                }
                              },
                              leading: Icon(
                                entity is Directory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: Colors.blue.shade700,
                              ),
                              title: Text(path.split('/').last),
                              subtitle: Text(path),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  // Optionally allow tap delete in addition to swipe
                                  deleteFavorite(path);
                                },
                              ),
                            ),
                          );
                        },
                      ));
  }
}

//This for the Highlighting the text in the search bar
TextSpan highlightMatch(String source, String query) {
  if (query.isEmpty) return TextSpan(text: source);
  final lowercaseSource = source.toLowerCase();
  final lowercaseQuery = query.toLowerCase();
  final start = lowercaseSource.indexOf(lowercaseQuery);
  if (start < 0) return TextSpan(text: source); // No match found
  final end = start + query.length;
  return TextSpan(
    children: [
      TextSpan(text: source.substring(0, start)),
      TextSpan(
        text: source.substring(start, end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextSpan(text: source.substring(end)),
    ],
  );
}
