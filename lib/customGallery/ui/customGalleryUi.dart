import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

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

  // ✅ ScrollController for horizontal scrolling
  final ScrollController _scrollController = ScrollController();

  // ✅ Add / Remove file from Import List
  void toggleFileSelection(File file) {
    setState(() {
      if (importFiles.contains(file)) {
        importFiles.remove(file);
      } else {
        importFiles.add(file);
      }
    });

    // ✅ Scroll to the end after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
      files = await settings.getFilesFromDirectory(root);  // Get File From Directory
      folders = await settings.getFoldersWithFiles(root.path); //Get File and folders
      setState(() {});
    }
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
          selectedFolder: selectedFolder,
          setState: setState,
          context: context,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selectedFolder ?? "All Files "),
              Icon(Icons.arrow_drop_down),
            ],
          ),
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
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      elevation: 2,
                      child: ListTile(

                        style: ListTileStyle.list,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: importFiles.contains(file)?Colors.blue.shade300:Colors.white, width: importFiles.contains(file)?2:0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hoverColor: Colors.blue.shade50,
                        selectedColor: Colors.blue.shade100,
                        leading:settings.getFileIcon(fileName),
                        title: Text(
                          fileName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis, // ✅ Ellipsis for long names
                          maxLines: 1,
                        ),
                        subtitle: settings.getFileDetails(file), // File Details
                        onTap: () => toggleFileSelection(file),
                        trailing: importFiles.contains(file)
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null
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
                //Import List Section Function
                child: importListSection(
                  // ✅ Pass required arguments
                  context,
                  importFiles: importFiles,
                  toggleFileSelection: toggleFileSelection,
                  importSelectedFiles: () => settings.importSelectedFiles(context, importFiles, setState),
                  scrollController: _scrollController,
                  settings: settings,
                )),
          )
        ],
      ),
    );
  }
}

//Import List UI
Widget importListSection(BuildContext context,
    {required List<File> importFiles,
    required Function(File file) toggleFileSelection,
    required VoidCallback importSelectedFiles,
    required ScrollController scrollController,
    required CustomGallerySetting settings}) {
  return Row(
    children: [
      // ✅ Horizontal File List
      Expanded(
        child: SizedBox(
          height: 100,
          child: ListView.builder(
            controller: scrollController, // ✅ Attach controller here
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
                      settings.getFileIcon(fileName),
                      SizedBox(height: 4),
                      Text(
                        fileName,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      IconButton(
                        icon: Icon(Icons.minimize, size: 28, color: Colors.red),
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
          padding: EdgeInsets.symmetric(vertical: 35, horizontal: 16),
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
  );
}

// Show Folder Selection Modal
Widget buildFolderSelectionSheet({
  required Map<String, List<String>> folders,
  required Function(String folderPath) onFolderSelected,
  String? selectedFolder,
  required StateSetter setState,
  required BuildContext context,
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
