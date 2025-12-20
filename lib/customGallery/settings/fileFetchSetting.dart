import 'dart:io';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'customGallerySetting.dart';

class FileFetchSettings {
  // ✅ Make allowedExtensions reactive
  RxList<String> allowedExtensions = [
    "pdf",
    "doc",
    "docx",
    "xls",
    "xlsx",
    "ppt",
    "pptx",
    "odt"
  ].obs;

  // ✅ Make restricted folders reactive
  RxList<String> restrictedFolders = ['Android', 'data', 'obb'].obs;

  // ✅ Recursive file fetching with GetX
  Future<List<File>> getFilesFromDirectory(
      Directory dir, {
        Set<String>? visited,
        bool showHiddenFiles = false,
      }) async {
    visited ??= <String>{};
    final List<File> files = [];

    if (visited.contains(dir.path)) return files;
    visited.add(dir.path);

    try {
      await for (final entity in dir.list(followLinks: false)) {
        final String entityName = p.basename(entity.path);

        if (!showHiddenFiles && entityName.startsWith('.')) continue;

        if (entity is File) {
          final String ext =
          p.extension(entity.path).replaceAll('.', '').toLowerCase();
          if (allowedExtensions.contains(ext)) {
            files.add(entity);
          }
        } else if (entity is Directory) {
          final String folderName = p.basename(entity.path);

          if (restrictedFolders
              .any((r) => r.toLowerCase() == folderName.toLowerCase())) {
            continue;
          }

          try {
            final childFiles = await getFilesFromDirectory(
              entity,
              visited: visited,
              showHiddenFiles: showHiddenFiles,
            );
            files.addAll(childFiles);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("Error accessing ${dir.path}: $e");
    }

    return files;
  }

  // ✅ Get folders with files reactively
  Future<RxMap<String, List<String>>> getFoldersWithFiles(String rootPath) async {
    RxMap<String, List<String>> folders = <String, List<String>>{}.obs;
    Directory rootDir = Directory(rootPath);

    List<File> files = await getFilesFromDirectory(rootDir);

    for (var file in files) {
      String folderPath = p.dirname(file.path);
      if (!folders.containsKey(folderPath)) {
        folders[folderPath] = [];
      }
      folders[folderPath]!.add(file.path);
    }

    return folders;
  }

  // ✅ SD Card detection using reactive updates
  Future<void> checkSdCard(RxnString sdCardPath, RxBool hasSdCard) async {
    try {
      List<String>? storagePaths =
      await ExternalPath.getExternalStorageDirectories();

      if (storagePaths != null && storagePaths.length > 1) {
        String path = storagePaths[1];
        Directory sdRoot = Directory(path);

        if (await sdRoot.exists()) {
          List<FileSystemEntity> sdFiles = sdRoot.listSync(followLinks: false);
          if (sdFiles.isNotEmpty) {
            debugPrint("✅ SD Card Found: $path");
            sdCardPath.value = path;
            hasSdCard.value = true;
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

  // ✅ Get filtered files
  List<File> getFilteredFiles({
    required List<File> allFiles,
    required String? folderPath,
    required String? fileType,
  }) {
    List<File> folderFiles;

    if (folderPath == null || folderPath == "All files") {
      folderFiles = List.from(allFiles);
    } else if (folderPath.split('/').last == '0') {
      folderFiles = allFiles
          .where((file) => p.dirname(file.path) == folderPath)
          .toList();
    } else if (folderPath
        .contains(RegExp(r'^\/storage\/[A-Z0-9]{4}-[A-Z0-9]{4}$'))) {
      folderFiles = allFiles
          .where((file) => p.dirname(file.path) == folderPath)
          .toList();
    } else {
      folderFiles =
          allFiles.where((file) => file.path.contains(folderPath)).toList();
    }

    if (fileType == null || fileType == "File Type" || fileType == "All Files") {
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

  // ✅ Storage permission
  Future<bool> isStoragePermissionGranted() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;
    if (sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  // ✅ Folder length and type UI with Obx
  Widget buildFolderLengthAndType(
      String folderName,
      RxList<File> allFiles,
      RxMap<String, List<File>> folders,
      String selectedFolder,
      ) {
    return Obx(() {
      int fileCount = 0;
      String storageType = "";

      if (folderName == "All files") {
        fileCount = allFiles.length;
      } else if (folderName.split('/').last == '0') {
        fileCount = folders.entries
            .where((entry) => entry.key.startsWith('/storage/emulated/0'))
            .fold(0, (sum, entry) => sum + entry.value.length);
        storageType = "Internal Storage";
      } else {
        fileCount = folders[folderName]?.length ?? 0;
        storageType = CustomGallerySetting().getStorageType(folderName);
      }

      String subtitleText = "$fileCount files";
      if (storageType.isNotEmpty && folderName != "All files") {
        subtitleText += " - $storageType";
      }

      return Text(
        subtitleText,
        style: TextStyle(
          color: selectedFolder == folderName
              ? Colors.blue.shade700
              : Colors.black87,
        ),
      );
    });
  }
}
