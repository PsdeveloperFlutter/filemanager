import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  final status = await Permission.manageExternalStorage.request();
  return status.isGranted;
}

const Map<String, String> categoryPaths = {
  'Downloads': '/storage/emulated/0/Download',
  'Images': '/storage/emulated/0/Pictures',
  'Videos': '/storage/emulated/0/Movies',
  'Audio': '/storage/emulated/0/Music',
  'Documents': '/storage/emulated/0/Documents',
};

class Category {
  final String name;
  final String path;
  final int count;

  Category({required this.name, required this.path, required this.count});
}

Future<int> getFileCount(String path) async {
  final directory = Directory(path);
  if (await directory.exists()) {
    return directory.listSync().length;
  }
  return 0;
}

Future<List<Category>> loadCategories() async {
  List<Category> list = [];
  for (final entry in categoryPaths.entries) {
    final count = await getFileCount(entry.value);
    list.add(Category(name: entry.key, path: entry.value, count: count));
  }
  return list;
}

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
  }

  Future<void> _initCategories() async {
    bool granted = await requestStoragePermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission not granted")),
      );
      return;
    }

    final data = await loadCategories();
    setState(() => categories = data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 300,
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(
                      categoryName: cat.name,
                      path: cat.path,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getCategoryIcon(cat.name), size: 20),
                        Text(
                          cat.name,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text('${cat.count} items',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Downloads':
        return Icons.download;
      case 'Images':
        return Icons.image;
      case 'Videos':
        return Icons.movie;
      case 'Audio':
        return Icons.music_note;
      case 'Documents':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }
}

void main() {
  runApp(MaterialApp(
    title: 'File Categories',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: CategoriesScreen(),
  ));
}

//This is for the detailing	of the CategoriesScreen.dart file

class CategoryDetailScreen extends StatelessWidget {
  final String path;
  final String categoryName;

  CategoryDetailScreen({required this.path, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final directory = Directory(path);
    final files = directory.existsSync()
        ? directory.listSync().whereType<FileSystemEntity>().toList()
        : [];

    return Scaffold(
      appBar: AppBar(title: Text('$categoryName')),
      body: files.isEmpty
          ? Center(child: Text("No items found in $categoryName"))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text(p.basename(file.path)),
                  subtitle: Text(file.path),
                  onTap: () async {
                    // Open the file or show more options
                    final result = await OpenFilex.open(file.path);
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to open file: ${result.message}')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
