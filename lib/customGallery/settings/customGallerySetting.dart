import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomGallerySetting {
// Allowed File Extensions
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

// ✅ Request Storage Permission for Android 10, 11, 12, 13+
  Future<bool> requestStoragePermission() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      // ✅ Android 11+ → Full access
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    } else {
      // ✅ Android 10 & Below
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

// ✅ Recursive file fetching for all Android versions
  Future<List<File>> getFilesFromDirectory(Directory dir,
      {Set<String>? visited}) async {
    visited ??= {};
    List<File> files = [];
    List<String> restrictedFolders = ["Android", "data", "obb"];

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
      // Ignore permission denied errors
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
      Navigator.pop(context, true); // Close the modal after a short delay
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
    } else {
      return [];
    }
  }

  // Icon set for Various Extension Files
  Icon getFileIcon(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: Colors.blue, size: 30);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart, color: Colors.green, size: 30);
      case 'ppt':
      case 'pptx':
        return Icon(Icons.slideshow, color: Colors.orange, size: 30);
      case 'odt':
        return Icon(
          Icons.article,
          color: Colors.purple,
          size: 30,
        );
      default:
        return Icon(Icons.insert_drive_file, color: Colors.purple, size: 22);
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
      String createdDate =
          DateFormat('dd MMM yyyy, hh:mm a').format(fileStat.changed);

      // ✅ Internal vs SD Card Path
      String filePath = file.path;
      String displayPath;
      if (filePath.startsWith('/storage/emulated/0')) {
        String relativePath = filePath.replaceFirst('/storage/emulated/0/', '');
        displayPath = "Internal → $relativePath";
      } else {
        displayPath = "SD Card → ${p.basename(filePath)}";
      }

      // ✅ Colors
      Color dateColor = Colors.deepPurple;
      Color sizeColor = Colors.green;
      Color pathColor = Colors.blueGrey;

      // ✅ Return Column with Two Rows
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Date + Size
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time, size: 16, color: dateColor),
              SizedBox(width: 4),
              Text(
                createdDate,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 12),
              Icon(Icons.storage, size: 16, color: sizeColor),
              SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: Text(
                  sizeText,
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),

          // Row 2: File Path
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder, size: 16, color: pathColor),
              SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: Text(
                  displayPath,
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
                  overflow: TextOverflow.ellipsis, // ✅ Ellipses for long paths
                  maxLines: 1,
                ),
              ),
            ],
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

  //File Types UI
// ✅ Show File Type Modal Bottom Sheet For User Selection of File Types
// ✅ File Types UI — working version
  void showFileTypeBottomSheet(BuildContext context, List<File> allFiles,
      Function(List<File>, String) onFilterApplied) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        List<String> fileTypes = [
          "All Files",
          "PDF",
          "DOC/DOCX",
          "XLS/XLSX",
          "TXT",
          "PPT/PPTX",
          "ODT"
        ];
        String? selectedFileType;

        return StatefulBuilder(
          builder: (context, setState) {
            void filterFilesByType(String? type) {
              setState(() {
                selectedFileType = type;
              });

              List<File> filteredFiles;
              if (type == "All Files" || type == null) {
                filteredFiles = List.from(allFiles);
              } else {
                filteredFiles = allFiles.where((file) {
                  String name = file.path.toLowerCase();
                  switch (type) {
                    case "PDF":
                      return name.endsWith(".pdf");
                    case "DOC/DOCX":
                      return name.endsWith(".doc") || name.endsWith(".docx");
                    case "XLS/XLSX":
                      return name.endsWith(".xls") || name.endsWith(".xlsx");
                    case "TXT":
                      return name.endsWith(".txt");
                    case "PPT/PPTX":
                      return name.endsWith(".ppt") || name.endsWith(".pptx");
                    case "ODT":
                      return name.endsWith(".odt");
                    default:
                      return false;
                  }
                }).toList();
              }
              // ✅ Agar "All Files" select hai to main UI mein "File Type" show hoga
              String displayText =
                  (type == "All Files" || type == null) ? "File Type" : type;
              // ✅ Pass both filtered files AND selected type to main UI
              onFilterApplied(filteredFiles, displayText);
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D62),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Text("Select File Types",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: fileTypes.length,
                      itemBuilder: (context, index) {
                        String fileType = fileTypes[index];
                        return Card(
                          elevation: 2,
                          child: RadioListTile<String>(
                            title: Text(fileType),
                            value: fileType,
                            groupValue: selectedFileType,
                            onChanged: (value) {
                              filterFilesByType(value);
                            },
                            activeColor: Colors.blue,
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
