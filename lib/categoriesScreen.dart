import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:filemanager/fileManageUi.dart';
import 'package:filemanager/recentFiles.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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

  Category({required this.name, required this.path});
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
    list.add(Category(name: entry.key, path: entry.value));
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

class CategoryDetailScreen extends StatefulWidget {
  final String path;
  final String categoryName;

  CategoryDetailScreen({required this.path, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> selectedFiles = [];
  bool isSelectionMode = false;

  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    final directory = Directory(widget.path);
    if (directory.existsSync()) {
      setState(() {
        files = directory.listSync().whereType<File>().toList();
      });
    }
  }

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedFiles.clear();
    });
  }

  void toggleFileSelection(FileSystemEntity file) {
    setState(() {
      if (selectedFiles.contains(file)) {
        selectedFiles.remove(file);
      } else {
        selectedFiles.add(file);
      }
    });
  }

  Future<void> _shareSelectedFiles() async {
    if (selectedFiles.isEmpty) return;
    try {
      List<XFile> xFiles = selectedFiles
          .map((file) => XFile(file.path,
              mimeType:
                  lookupMimeType(file.path) ?? 'application/octet-stream'))
          .toList();
      if (xFiles.length == 1) {
        // Safe to add text with single file
        await Share.shareXFiles(
          xFiles,
          text: 'Shared from File Manager',
          subject: p.basename(xFiles.first.path),
        );
      } else {
        // Multiple file sharing: omit 'text' to avoid crashing
        await Share.shareXFiles(xFiles);
      }
      toggleSelectionMode();
    } catch (e) {
      print("Error sharing files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share files: $e")),
      );
    }
  }

  void _deleteFile(int index) async {
    // This is the delete function for single
    final file = files[index];
    try {
      if (await File(file.path).exists()) {
        await File(file.path).delete();
        setState(() {
          files.removeAt(index);
        });
      }
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName}'),
        // This is the title of the app bar
        actions: isSelectionMode // This is the selection mode
            ? [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: _shareSelectedFiles, //This is the share function
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: toggleSelectionMode, //This is the close function
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    deletion(); //This is the delete function for the Multiple deletion
                  },
                ),
                IconButton(
                  onPressed: () async {
                    final targetPath = await _selectTargetDirectory();
                    if (targetPath != null) {
                      await moveSelectedFiles(targetPath);
                    }
                  },
                  icon: Icon(Icons.drive_file_move, color: Colors.blue),
                ),
              ]
            : null,
      ),
      body: files.isEmpty
          ? Center(child: Text("No items found in ${widget.categoryName}"))
          : GestureDetector(
              onLongPress: () {
                toggleSelectionMode();
              },
              child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = selectedFiles.contains(file);
                    return Card(
                      child: ListTile(
                        leading: isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  toggleFileSelection(file);
                                },
                              )
                            : setIcon(file), // This is the setIcon function
                        title: Text(p.basename(file.path)),
                        subtitle: Text(file.path),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteFile(index), //This is the delete function
                        ),
                        onTap: () async {
                          // Open the file or show more options
                          openFileWithIntent(file.path, context);
                        },
                      ),
                    );
                  }),
            ),
    );
  }

//This is for the deletion of multiple File
  void deletion() {
    setState(() {
      for (var file in selectedFiles) {
        if (files.contains(file)) {
          files.remove(file);
          File(file.path).deleteSync();
        }
      }
      selectedFiles.clear();
      isSelectionMode = false;
    });
  }
  Future<String?> _selectTargetDirectory()async{// This function is used to select the target directory for moving files
    try{
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        return selectedDirectory;
      } else {
        return null;
      }
    }catch(e){
     print("Error selecting directory: $e");
    }
  }
  Future<void> moveSelectedFiles(String targetPath) async { //
    try{
      for(var file in selectedFiles){
        final fileName=p.basename(file.path);
        final newpath=p.join(targetPath,fileName);
        await File(file.path).rename(newpath);
        setState(() {
          files.removeWhere((file)=>selectedFiles.contains(file));
          selectedFiles.clear();
          isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Files moved successfully")),
        );
      }
    }catch(e){
        print("Error moving files: $e");
        setState(() {
          selectedFiles.clear(); // Clear the list to avoid concurrent modification
          isSelectionMode = false;
        });
    }
  }
}
