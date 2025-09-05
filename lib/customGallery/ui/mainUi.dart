import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: CustomGalleryApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class CustomGalleryApp extends StatefulWidget {
  const CustomGalleryApp({super.key});

  @override
  State<CustomGalleryApp> createState() => _CustomGalleryAppState();
}

class _CustomGalleryAppState extends State<CustomGalleryApp> {
  // ✅ Folder List
  List<File> files = []; // All Files
  Map<String, List<String>> folders = {}; // Folders with Files
  String? selectedFolder; // Currently Selected Folder

  // ✅ Files user clicked on → shown at the bottom horizontal list
  List<File> importFiles = [];

  // Settings Instance
  final CustomGallerySetting settings = CustomGallerySetting();

  // ✅ Add / Remove file from Import List
  void toggleFileSelection(File file) {
    setState(() {
      if (importFiles.contains(file)) {
        importFiles.remove(file);
      } else {
        importFiles.add(file);
      }
    });
  }

  // ✅ Import files into new folder
  Future<void> importSelectedFiles() async {
    if (importFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No files selected for import")),
      );
      return;
    }

    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      Directory importDir = Directory(p.join(appDir.path, "ImportedFiles"));
      if (!await importDir.exists()) await importDir.create();

      for (File file in importFiles) {
        String newPath = p.join(importDir.path, p.basename(file.path));
        await file.copy(newPath);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Files imported successfully!")),
      );

      setState(() {
        importFiles.clear(); // Clear after importing
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  // Load Files and Folders
  Future<void> loadFiles() async {
    bool granted = await settings.requestStoragePermission();
    if (granted) {
      Directory root = Directory('/storage/emulated/0/');
      files = await settings.getFilesFromDirectory(root);
      folders = await settings.getFoldersWithFiles(root.path);
      setState(() {});
    }
  }

  // Show Folder Selection Modal
  Widget buildFolderSelectionSheet({
    required Map<String, List<String>> folders,
    required Function(String folderPath) onFolderSelected,
  }) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  "All System Folders",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: folders.keys.length,
              itemBuilder: (context, index) {
                String folderPath = folders.keys.elementAt(index);
                List<String> filesInFolder = folders[folderPath] ?? [];
                int fileCount = filesInFolder.length;

                return Card(
                  elevation: 1,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.folder, color: Colors.orange),
                    trailing: Radio<String>(
                      value: folderPath,
                      groupValue: selectedFolder,
                      onChanged: (value) {
                        setState(() {
                          selectedFolder = value;
                        });
                        onFolderSelected(folderPath);
                      },
                    ),
                    title: Text(folderPath.split('/').last),
                    subtitle: Text("$fileCount files"),
                    onTap: () {
                      setState(() {
                        selectedFolder = folderPath;
                      });
                      onFolderSelected(folderPath);
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void showFolderSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return buildFolderSelectionSheet(
          folders: folders,
          onFolderSelected: (folderPath) {
            setState(() {
              selectedFolder = folderPath.split('/').last;
              files = folders[folderPath]!.map((path) => File(path)).toList();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ✅ Fetch Files from System File Manager
  void pickFilesFromSystemGallery() async {
    List<String> allowedExtensions = [
      "pdf",
      "doc",
      "docx",
      "xls",
      "xlsx",
      "ppt",
      "pptx",
      "odt"
    ];

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      List<String> selectedFiles = result.paths.whereType<String>().toList();

      setState(() {
        files = selectedFiles.map((path) => File(path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: selectedFolder == null
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedFolder = null;
                    files = folders.values
                        .expand((list) => list)
                        .map((path) => File(path))
                        .toList();
                  });
                },
              ),
        title: GestureDetector(
          onTap: showFolderSelection,
          child: Text(selectedFolder ?? "All Files"),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: pickFilesFromSystemGallery,
          )
        ],
      ),
      body: Stack(
        children: [
          // ✅ Main File List
          files.isEmpty
              ? Center(child: Text("No files found"))
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 130), // space for bottom bar
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    File file = files[index];
                    String fileName = file.path.split('/').last;
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading:
                            Icon(Icons.insert_drive_file, color: Colors.green),
                        title: Text(fileName),
                        onTap: () => toggleFileSelection(file),
                      ),
                    );
                  },
                ),

          // ✅ Bottom Horizontal List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.blue.shade300, width: 1),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: Row(
                children: [
                  // ✅ Horizontal File List
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: importFiles.length,
                        itemBuilder: (context, index) {
                          File file = importFiles[index];
                          String fileName = p.basename(file.path);

                          return Container(
                            width: 100,
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.insert_drive_file,
                                      color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text(
                                    fileName,
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.minimize,
                                        size: 28, color: Colors.red),
                                    onPressed: () => toggleFileSelection(file),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ✅ Import Button on Right Side
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 35, horizontal: 16),
                      backgroundColor: Colors.blue.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: importSelectedFiles,
                    child: Text(
                      "Import ${importFiles.length}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
