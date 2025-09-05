import 'dart:io';

import 'package:path/path.dart' as p;
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
}
