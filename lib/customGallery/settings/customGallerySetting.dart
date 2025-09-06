import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomGallerySetting {
  //Allowed File Extensions
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

  // Function to request storage permission
  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    //Request permission if not granted
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  //Get Files by Extension
  // We’ll scan the device storage for files with the required extensions.
  /// ✅ SAFE: Get files from directory without infinite loops
  Future<List<File>> getFilesFromDirectory(Directory dir,
      {Set<String>? visited}) async {
    visited ??= {};
    List<File> files = [];
    List<String> restrictedFolders = ["Android", "data", "obb"];

    // Avoid scanning the same folder twice
    if (visited.contains(dir.path)) return files;
    visited.add(dir.path);

    try {
      await for (var entity in dir.list(followLinks: false)) {
        if (entity is File) {
          String ext =
              p.extension(entity.path).replaceAll('.', '').toLowerCase();
          if (allowedExtensions.contains(ext)) {
            files.add(entity);
          }
        } else if (entity is Directory) {
          String folderName = p.basename(entity.path);

          // Skip restricted and hidden folders
          if (!restrictedFolders.contains(folderName) &&
              !folderName.startsWith(".")) {
            try {
              files.addAll(
                  await getFilesFromDirectory(entity, visited: visited));
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      // Ignore folders we can't access
    }
    return files;
  }

  //Get Folders with Files
  // This will help in the Modal Bottom Sheet part.

  /// ✅ Get folders with files safely
  Future<Map<String, List<String>>> getFoldersWithFiles(String rootPath) async {
    Map<String, List<String>> folders = {};
    Directory rootDir = Directory(rootPath);

    List<File> files = await getFilesFromDirectory(rootDir);

    for (var file in files) {
      String folderPath = p.dirname(file.path);
      folders.putIfAbsent(folderPath, () => []).add(file.path);
    }

    return folders;
  }

  // ✅ Import files into new folder Logic
  Future<void> importSelectedFiles(BuildContext context, List<File> importFiles,
      StateSetter setState) async {
    if (importFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No files selected for import")),
      );
      return;
    }

    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      Directory baseImportDir = Directory(p.join(appDir.path, "ImportedFiles"));

      // Create base ImportedFiles folder if it doesn't exist
      if (!await baseImportDir.exists()) {
        await baseImportDir.create();
      }

      // Step 2: Create folder with today's date + current time
      String folderName =
          getDateTimeFolderName(); // e.g., "06-09-2025_10-30-15"
      Directory dateTimeFolder =
          Directory(p.join(baseImportDir.path, folderName));

      if (!await dateTimeFolder.exists()) {
        await dateTimeFolder.create();
      }
      // Step 3: Copy files into this new folder
      for (File file in importFiles) {
        String newPath = p.join(dateTimeFolder.path, p.basename(file.path));
        await file.copy(newPath);
      }

      //Step 4: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Files imported successfully!")),
      );
      Navigator.pop(context,true); // Close the modal after a short delay
      setState(() {
        importFiles.clear(); // Clear after importing
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ✅ Helper: Get today's date + time as folder name
  String getDateTimeFolderName() {
    DateTime now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    String year = now.year.toString();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');

    return "$day-$month-$year\_$hour-$minute-$second";
  }

  //Folder Fetch Logic
  Future<List<String>> getImportedFolders() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory baseImportDir = Directory(p.join(appDir.path, "ImportedFiles"));
    if (await baseImportDir.exists()) {
      List<FileSystemEntity> entities = baseImportDir.listSync();
      return entities
          .where(((e) => FileSystemEntity.isDirectorySync(e.path)))
          .map((e) => e.path)
          .toList();
    }
    else{
      return [];
    }
  }


  // Icon set for Various Extension Files
 Icon getFileIcon(String fileName){
    String ext=fileName.split('.').last.toLowerCase();
    switch(ext){
      case 'pdf':
        return Icon(Icons.picture_as_pdf,color: Colors.red,);
      case 'doc':
      case 'docx':
        return Icon(Icons.description,color: Colors.blue,);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart,color: Colors.green,);
      case 'ppt':
      case 'pptx':
        return Icon(Icons.slideshow,color: Colors.orange,);
      case 'odt':
        return Icon(Icons.article,color: Colors.purple,);
      default:
        return Icon(Icons.insert_drive_file,color: Colors.purple,);
    }
 }


  // File Subtitle Widget and Info of File'S
  Widget getFileDetails(File file) {
    try {
      final fileStat = file.statSync();

      // ✅ File Size Formatting
      int bytes = fileStat.size;
      String sizeText;
      if (bytes < 1024) {
        sizeText = "$bytes B";
      } else if (bytes < 1024 * 1024) {
        sizeText = "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        sizeText = "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }

      // ✅ Created Date
      String createdDate = DateFormat('dd MMM yyyy, hh:mm a').format(fileStat.changed);

      // ✅ Internal vs SD Card Path
      String filePath = file.path;
      String displayPath;
      if (filePath.startsWith('/storage/emulated/0')) {
        String relativePath = filePath.replaceFirst('/storage/emulated/0/', '');
        displayPath = "Internal → $relativePath";
      } else {
        displayPath = "SD Card → ${p.basename(filePath)}";
      }

      // ✅ Colors for Icons
      Color pathColor = Colors.blueAccent;
      Color dateColor = Colors.deepPurple;
      Color sizeColor = Colors.green;

      // ✅ Return Row Layout with Icons
      return Row(
        children: [
          // 📂 Path
          Icon(Icons.folder, size: 16, color: pathColor),
          SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              displayPath,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: 10),

          // 📅 Date
          Icon(Icons.access_time, size: 16, color: dateColor),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              createdDate,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: 10),

          // 📦 Size
          Icon(Icons.storage, size: 16, color: sizeColor),
          SizedBox(width: 4),
          Text(
            sizeText,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } catch (e) {
      return Text(
        "Error loading file info",
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
      );
    }
  }
}
