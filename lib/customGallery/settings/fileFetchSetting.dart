import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;
import 'package:pdf_render/pdf_render.dart';
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
//This is a custom file fetch settings class for fetching files from device storage.
class FileFetchSettings {
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

// ✅ Recursive file fetching for all Android versions
  Future<List<File>> getFilesFromDirectory(
    Directory dir, {
    Set<String>? visited,
    bool showHiddenFiles = false,
  }) async {
    visited ??= {};
    List<File> files = [];
    List<String> restrictedFolders = ["Android", "data", "obb"];

    if (visited.contains(dir.path)) return files;
    visited.add(dir.path);

    try {
      await for (var entity in dir.list(followLinks: false)) {
        String entityName = p.basename(entity.path);
        // ✅ Skip hidden files/folders if showHiddenFiles = false
        if (!showHiddenFiles && entityName.startsWith(".")) {
          continue;
        }
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

//✔ This is the Function Responsible for Checking if the SD Card is in User Device or not.

  Future<void> checkSdCard(
      Function setState, Function(String) onSdCardFound) async {
    try {
      List<String>? storagePaths =
          await ExternalPath.getExternalStorageDirectories();

      // कम से कम 2 paths चाहिए → Internal + SD Card
      if (storagePaths != null && storagePaths.length > 1) {
        String sdCardPath = storagePaths[1]; // SD Card path

        Directory sdRoot = Directory(sdCardPath);
        if (await sdRoot.exists()) {
          // SD Card के अंदर कम से कम 1 फाइल या फोल्डर होना चाहिए
          List<FileSystemEntity> sdFiles = sdRoot.listSync(followLinks: false);

          if (sdFiles.isNotEmpty) {
            debugPrint("✅ SD Card Found: $sdCardPath");
            setState(() {
              onSdCardFound(sdCardPath); // SD Card path पास करो
            });
          } else {
            debugPrint("⚠️ SD Card Empty है");
          }
        } else {
          debugPrint("⚠️ SD Card Path Exists नहीं करता");
        }
      } else {
        debugPrint("❌ SD Card Not Available");
      }
    } catch (e) {
      debugPrint("SD Card Detection Error: $e");
    }
  }

  // ✅ Get Filtered Files based on folder and file type

  List<File> getFilteredFiles({
    required List<File> allFiles,
    required String? folderPath,
    required String? fileType,
  }) {
    // Folder filter
    List<File> folderFiles;
    if (folderPath == null || folderPath == "All files") {
      folderFiles = List.from(allFiles);
    } else {
      folderFiles =
          allFiles.where((file) => file.path.contains(folderPath)).toList();
    }

    // File type filter
    if (fileType == null ||
        fileType == "File Type" ||
        fileType == "All Files") {
      return folderFiles;
    } else {
      return folderFiles.where((file) {
        String name = file.path.toLowerCase();
        switch (fileType) {
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
  }

  //Only Check Status of Permission
  Future<bool> isStoragePermissionGranted() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;
    if (sdkInt >= 30) {
      // ✅ Android 11+
      return await Permission.manageExternalStorage.isGranted;
    } else {
      // ✅ Android 10 & below
      return await Permission.storage.isGranted;
    }
  }

  // ✅ Get PDF first page AS  Icon based on PDF
  Future<ImageProvider?> getPdfFirstPageImage(String path,
      {int width = 150,
        int height = 200,
        required Map<String, ImageProvider> cache}) async {
    try {
      if (cache.containsKey(path)) return cache[path];

      final doc = await PdfDocument.openFile(path);
      final page = await doc.getPage(1);

      final pageImage = await page.render(width: width, height: height);

      final uiImage = await pageImage.createImageIfNotAvailable();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        uiImage.dispose();
        return null;
      }

      final pngBytes = byteData.buffer.asUint8List();
      uiImage.dispose();

      final provider = MemoryImage(pngBytes);
      cache[path] = provider;
      return provider;
    } catch (e) {
      debugPrint('PDF thumbnail error: $e');
      return null;
    }
  }


}
