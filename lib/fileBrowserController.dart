import 'dart:io';

import 'package:archive/archive.dart';
import 'package:filemanager/selectDestionation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileBrowserController extends GetxController {
  // Holds copied item (file or folder)
  RxBool refreshValue = false.obs; //This is for the Refreshing purpose
  FileSystemEntity? copiedEntity; //
  RxBool isDarkTheme = false.obs; // This is for the Dark Theme
  static const _themekey = 'isDarkTheme'; // Key for SharedPreferences

  ThemeMode get themeMode => isDarkTheme.value
      ? ThemeMode.dark
      : ThemeMode.light; //This is for the getting Theme data
  void toggleTheme() {
    //This is for the changing the theme of app
    isDarkTheme.value = !isDarkTheme.value;
    Get.changeThemeMode(themeMode);
    _saveThemeToPrefs(isDarkTheme.value); // Save the theme preference
  }

  Future<void> loadThemeFromPrefs() async {
    //This is for the loading the theme from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkTheme.value = prefs.getBool(_themekey) ?? false;
    Get.changeThemeMode(isDarkTheme.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _saveThemeToPrefs(bool isDark) async {
    //This is for the saving the theme to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themekey, isDark);
  }

  Future<void> _saveLayoutToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGridView.value);
  }

  Future<void> loadLayoutFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isGridView.value = prefs.getBool('isGridView') ?? false;
  }

  //This is for the file and folder list
  Rx<Directory> currentDirectory =
      Directory('/storage/emulated/0').obs; // Default to internal storage
  var isGridView = false.obs; // Default to list view
  final fileName =
      <FileSystemEntity>[].obs; // This is for the file and folder list
  final searchQuery = ''.obs; // This is for the search query
  final List<Directory> _navigationStack =
      []; // This is for the navigation stack
  final canGoBack = false.obs; // This is for the go back functionality
  // This is for the filtered files based on search query
  List<FileSystemEntity> get filteredFiles => fileName
      .where(
          (file) => p.basename(file.path).contains(searchQuery.toLowerCase()))
      .toList();
  //this function is for the goback functionality
  void goBackDirectory() {
    if (_navigationStack.isNotEmpty) {
      final previous = _navigationStack.removeLast();
      listFiles(previous);
      canGoBack.value = _navigationStack.isNotEmpty; // update here
    }
  }

  //this function is for update
  void updateSearch(query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    super.onInit();
    _initStorage();
  }
  // This is for the initialization of the storage and listing files
  Future<void> _initStorage() async {
    if (await Permission.storage.request().isGranted) {
      listFiles(currentDirectory.value);
    }
  }

  //This is for the functionality of the BreadCrumb items
  List<Map<String, String>> getPathSegments(String fullPath) {
    final segments = <Map<String, String>>[];
    final parts = fullPath.split(Platform.pathSeparator);
    String currentPath = Platform.pathSeparator; // Start with root `/`
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      currentPath = p.join(currentPath, part);
      segments.add({
        "name": part,
        "path": currentPath,
      });
    }
    return segments;
  }
// This is for the listing the files in the current directory
  void listFiles(Directory dir) {
    try {
      final files = dir.listSync();
      fileName.value = files;
      currentDirectory.value = dir;
      canGoBack.value = _navigationStack.isNotEmpty; // update here
    } catch (e) {
      Get.snackbar("Error", "Failed to list directory");
    }
  }

  //For doing the Toggle option list to Grid view
  void toggleView() {
    isGridView.value = !isGridView.value;
    _saveLayoutToPrefs();
  }

  //for getting the file size
  String getFileSize(FileSystemEntity entity) {
    if (entity is File) {
      final bytes = entity.lengthSync();
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    }
    return "-";
  }

//for opening the directory
  void openDirectory(FileSystemEntity entity, BuildContext context) {
    if (entity is Directory) {
      _navigationStack
          .add(currentDirectory.value); // Push current before navigating
      listFiles(entity);
      canGoBack.value = _navigationStack.isNotEmpty; // Update back button state
    }
  }

  //this is for the Rename Functionality
  Future<void> renameFileOrFolder(
      BuildContext context, FileSystemEntity entity) async {
    final oldPath = entity.path;
    final isDirectory = entity is Directory;
    final oldName = oldPath.split(Platform.pathSeparator).last;
    // Protect against renaming system folders
    if (oldPath.contains('/ColorOS') ||
        oldPath.contains('/Android') ||
        oldPath == '/storage/emulated/0') {
      feedBack(context, 'Cannot rename system or restricted folders.');
      return;
    }
    final TextEditingController controller =
        TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Rename ${isDirectory ? "Folder" : "File"}"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final input = controller.text.trim();
                if (input.isNotEmpty) {
                  Navigator.of(context).pop(input);
                }
              },
              child: const Text("Set"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
    if (newName == null || newName.isEmpty) return;
    final newPath = oldPath.replaceFirst(RegExp(r'[^/\\]+$'), newName);
    try {
      if (isDirectory) {
        await (entity as Directory).rename(newPath);
      } else {
        await (entity as File).rename(newPath);
      }
      feedBack(context, 'Renamed to $newName');
      refreshFiles();
    } catch (e) {
      feedBack(context, 'Rename failed: ${e.toString()}');
    }
  }

  //This code for the delete functionality of the files and folders
  void deleteFileOrFolder(FileSystemEntity entity, BuildContext context) async {
    try {
      if (entity.path.contains("/Android") ||
          entity.path.contains("/ColorOS") ||
          entity.path == "/storage/emulated/0") {
        feedBack(context, 'Cannot delete system or restricted folders.');
        return;
      }
      bool isDirectory = entity is Directory;
      if (isDirectory) {
        await (entity as Directory).delete(recursive: true);
      } else {
        await (entity as File).delete();
      }
      // Show success message
      feedBack(context, "Item deleted successfully.");
      // Refresh file list
      refreshFiles();
    } catch (e) {
      feedBack(context, "Failed to delete: $e");
    }
  }

  //This is for the zip file creation and after that share the file
  Future<void> shareFile(BuildContext context, FileSystemEntity entity) async {
    try {
      //Get temporary directory path
      final tempDir = await getTemporaryDirectory();
      final name = p.basename(entity.path);
      final zippath = p.join(tempDir.path, '$name.zip');
      final archive = Archive();
      if (entity is Directory) {
        await _addDirectoryToArchive(entity, archive, entity.path);
      } else if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      } else {
        throw Exception("Unsupported file type");
      }
      //Encode  the archive as zip
      final zipEncoder = ZipEncoder();
      final zipFileData = zipEncoder.encode(archive);
      //Save to disk
      final zipFile = File(zippath);
      await zipFile.writeAsBytes(zipFileData);
      //share the zip file
      await Share.shareXFiles([XFile(zipFile.path)],
          text: 'Here is your zipped file');
    } catch (e) {
      feedBack(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _addDirectoryToArchive(
      Directory dir, Archive archive, String basePath) async {
    final List<FileSystemEntity> entities = dir.listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      final relativePath = p.relative(entity.path, from: basePath);
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        archive.addFile(ArchiveFile('$relativePath/', 0, []));
      } else {
        throw Exception("Unsupported file type");
      }
    }
  }

  //For Opening the Files and another folders and directory and Another Materials
  Future<void> openFile(FileSystemEntity entity, BuildContext context) async {
    try {
      if (entity is File) {
        final result = await OpenFilex.open(entity.path);
        if (result.type == ResultType.noAppToOpen) {
          feedBack(context, 'No app found to open this file');
        } else if (result.type == ResultType.error) {
          feedBack(context, 'Failed to open file: ${result.message}');
        }
      } else {
        feedBack(context, 'Cannot open a folder');
      }
    } catch (e) {
      feedBack(context, 'Error opening file: $e');
    }
  }

  //This code is responsible for the Sorting purpose of the files
  void sortFilesByOption(String option) {
    final files = List<FileSystemEntity>.from(fileName);
    files.sort((a, b) {
      switch (option) {
        case 'Name A → Z':
          return p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase());
        case 'Name Z → A':
          return p
              .basename(b.path)
              .toLowerCase()
              .compareTo(p.basename(a.path).toLowerCase());
        case 'Largest first':
          return _getSize(b).compareTo(_getSize(a));
        case 'Smallest first':
          return _getSize(a).compareTo(_getSize(b));
        case 'Newest date first':
          return _getModifiedDate(b).compareTo(_getModifiedDate(a));
        case 'Oldest date first':
          return _getModifiedDate(a).compareTo(_getModifiedDate(b));
        default:
          return 0; // No sorting
      }
    });
    fileName.value = files;
  }

  int _getSize(FileSystemEntity entity) {
    if (entity is File) {
      return entity.lengthSync();
    }
    return 0;
  }

  DateTime _getModifiedDate(FileSystemEntity entity) {
    return entity.statSync().modified;
  }

  // You should already have this for listing files

  void refreshFiles() {
    refreshValue.value = true; // Show loader/spinner
    Future.delayed(const Duration(milliseconds: 500), () {
      final dir = currentDirectory.value;
      if (dir.existsSync()) {
        final newList = dir.listSync();
        fileName.clear();
        fileName.addAll(newList); // Update the reactive list
      }
      refreshValue.value = false; // Hide loader/spinner
    });
  }

  Future<void> createNewFolder(String folderName) async {
    final path = "${currentDirectory.value.path}/$folderName";
    final newDir = Directory(path);

    if (await newDir.exists()) {
      Get.snackbar("Folder Exists", "A folder with this name already exists.");
    } else {
      await newDir.create(recursive: true); // safer creation
      Get.snackbar("Folder Created", "New folder created successfully.");
      refreshFiles(); // make sure refreshFiles updates UI properly
    }
  }

  //This is the dialog box of the deletion purpose
  void showDeleteDialog(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete"),
        content:
            Text("Are you sure you want to delete ${p.basename(entity.path)}?"),
        actions: [
          TextButton(
            onPressed: () {
              deleteFileOrFolder(entity, context);
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  //This is the dialog box of the create new folder
  void showCreateFolderDialog(BuildContext context) {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create New Folder"),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(hintText: "Enter folder name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final name = folderNameController.text.trim();
              if (name.isNotEmpty) {
                Get.find<FileBrowserController>().createNewFolder(name);
                Navigator.of(context).pop(); // close dialog
              } else {
                Get.snackbar("Error", "Folder name cannot be empty.");
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  //This is the code of the Move functionality
  List<FileSystemEntity> itemsToMove = [];
  List<FileSystemEntity> itemsToCopy = [];

  /// ✅ Call this for single item move/copy
  void initiateMoveOrCopySingle(FileSystemEntity entity, String mode) {
    clearSelection(); // clear previous selection
    initiateMoveOrCopyMultiple([entity], mode); // treat as multi with 1 item
  }

  void initiateMoveOrCopyMultiple(
      List<FileSystemEntity> entities, String mode) {
    clearSelection();
    if (mode == "copy") {
      itemsToCopy.assignAll(entities); // ✅ this too
    } else if (mode == "move") {
      itemsToMove.assignAll(entities); // ✅ this too
    }
    Get.bottomSheet(
      backgroundColor: Colors.white,
      SelectDestinationSheet(mode: mode),
    );
  }

  /// ✅ Clear old selections
  void clearSelection() {
    itemsToCopy.clear();
    itemsToMove.clear();
    selectedDestination.value = null;
  }

  //This is the code Responsible for the Destination Folder and selected Destination
  final RxList<Directory> destinationFolders = <Directory>[].obs;
  var selectedDestination = Rxn<Directory>();

  void browseInternalStorage() {
    final dir = Directory('/storage/emulated/0');
    if (dir.existsSync()) {
      destinationFolders.value = dir.listSync().whereType<Directory>().toList();
      selectedDestination.value = null;
    }
  }

  void selectDestination(Directory folder) {
    selectedDestination.value = folder;
  }

  final Rx<Directory> currentDestinationDir =
      Directory('/storage/emulated/0').obs;

  void browseDestinationFolder(Directory dir) {
    currentDestinationDir.value = dir;
    final all = dir.listSync();
    destinationFolders.value = all
        .whereType<Directory>()
        .where((d) =>
            !d.path.contains("/Android") && // Skip system folders
            !d.path.contains("/ColorOS"))
        .toList();
  }

  //This is create the new folder When the user want to move folder and files
  void createFolderInDestination() async {
    TextEditingController folderNameController = TextEditingController();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text("New Folder"),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(hintText: "Enter folder name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: folderNameController.text),
            child: const Text("Create"),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final newPath = "${selectedDestination.value?.path}/$result";
      final newDir = Directory(newPath);
      if (!newDir.existsSync()) {
        await newDir.create();
        browseInternalStorage(); // Refresh destination folder list
        Get.snackbar("Created", "Folder '$result' created.");
      } else {
        Get.snackbar("Exists", "Folder with the same name exists.");
      }
    }
  }

  //This is for Execute Move functionality make sure of that
  void executeMove() async {
    final destination = selectedDestination.value;
    if (destination == null || itemsToMove.isEmpty) {
      Get.snackbar("Error", "Please select file/folders to move");
      return;
    }
    for (final entity in itemsToMove) {
      await handleFileOperation(
        source: entity,
        destination: destination,
        operation: 'move',
        performOperation: (newPath) async => await entity.rename(newPath),
      );
    }
    itemsToMove.clear();
  }

  void executeCopy() async {
    final destination = selectedDestination.value;
    if (destination == null || itemsToCopy.isEmpty) {
      Get.snackbar("Error", "Please select file/folders to copy");
      return;
    }
    for (final entity in itemsToCopy) {
      await handleFileOperation(
        source: entity,
        destination: destination,
        operation: 'copy',
        performOperation: (newPath) async => await copyEntity(entity, newPath),
      );
    }
    itemsToCopy.clear();
  }

  /// 🔁 Shared file operation handler
  Future<void> handleFileOperation({
    required FileSystemEntity source,
    required Directory destination,
    required String operation, // 'copy' or 'move'
    required Future<void> Function(String newPath) performOperation,
  }) async {
    final fileName = source.path.split('/').last;
    final newPath = "${destination.path}/$fileName";

    // Prevent self-location operation
    if (source.parent.path == destination.path) {
      Get.snackbar("Invalid", "File is already in this location.");
      return;
    }
    final newEntity =
        FileSystemEntity.typeSync(source.path) == FileSystemEntityType.directory
            ? Directory(newPath)
            : File(newPath);
    if (newEntity.existsSync()) {
      final choice = await Get.dialog(
        AlertDialog(
          title: Text("File Exists"),
          content: Text("A file/folder with the same name exists."),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: 'rename'),
                child: Text("Rename")),
            TextButton(
                onPressed: () => Get.back(result: 'overwrite'),
                child: Text("Overwrite")),
            TextButton(
                onPressed: () => Get.back(result: 'cancel'),
                child: Text("Cancel")),
          ],
        ),
      );
      if (choice == 'rename') {
        final newName = await Get.defaultDialog<String>(
          title: "Rename File",
          content: TextField(
            onSubmitted: (val) => Get.back(result: val),
            decoration: InputDecoration(hintText: "New name"),
          ),
        );
        if (newName != null && newName.isNotEmpty) {
          final renamedPath = "${destination.path}/$newName";
          await performOperation(renamedPath);
        }
      } else if (choice == 'overwrite') {
        await performOperation(newPath);
      } else {
        return;
      }
    } else {
      await performOperation(newPath);
    }
    Get.back(); // Close the sheet
    refreshFiles(); // Refresh view
    Get.snackbar("Success",
        "Item ${operation == 'copy' ? 'copied' : 'moved'} successfully.");
  }

  Future<void> copyEntity(FileSystemEntity source, String newPath) async {
    if (source is File) {
      await File(source.path).copy(newPath);
    } else if (source is Directory) {
      final newDir = Directory(newPath);
      if (!newDir.existsSync()) await newDir.create(recursive: true);
      final entities = Directory(source.path).listSync();
      for (var entity in entities) {
        final entityName = entity.path.split('/').last;
        await copyEntity(entity, "$newPath/$entityName");
      }
    }
  }

  // At the top
  var isSelectionMode = false.obs;
  var selectedItems = <FileSystemEntity>[].obs;

  //for doing toggling of Selection Mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedItems.clear();
    }
  }

  void toggleItemSelection(FileSystemEntity entity) {
    if (selectedItems.contains(entity)) {
      selectedItems.remove(entity);
    } else {
      selectedItems.add(entity);
    }
    selectedItems.refresh(); // Force UI update!
  }

  void selectAllItems() {
    selectedItems.assignAll(fileName);
  }

  void clearAllItems() {
    selectedItems.clear();
    isSelectionMode.value = false;
  }

  //this is for the Snackbar purpose
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> feedBack(
      BuildContext context, String value) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }
}
