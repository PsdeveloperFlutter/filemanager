import 'dart:io';
import 'package:intl/intl.dart';
import 'package:filemanager/passwordProtection.dart';
import 'package:filemanager/sqfliteDatabase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'fileBrowserController.dart';
import 'package:path/path.dart' as p;
class FileBrowserScreen extends StatefulWidget {
  FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => FileBrowserScreenState();
}

class FileBrowserScreenState extends State<FileBrowserScreen> {
  final fileController = Get.put(FileBrowserController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
            floatingActionButton: Obx(() {
              if (!fileController.isSelectionMode.value ||
                  fileController.selectedItems.isEmpty) {
                return const SizedBox();
              }
               return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.copy,
                      label: "Copy",
                      heroTag: "copy",
                      onPressed: () {
                        fileController.initiateMoveOrCopyMultiple(
                            fileController.selectedItems, "copy");
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.drive_file_move,
                      label: "Move",
                      heroTag: "move",
                      onPressed: () {
                        fileController.initiateMoveOrCopyMultiple(
                            fileController.selectedItems, "move");
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: "Delete",
                      heroTag: "delete",
                      onPressed: () async {
                        final confirm = await Get.dialog(AlertDialog(
                          title: const Text("Delete Selected?"),
                          content: const Text(
                              "This will permanently delete selected files/folders."),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ));

                        if (confirm == true) {
                          for (final file in fileController.selectedItems) {
                            try {
                              if (file.existsSync()) {
                                file.deleteSync(recursive: true);
                              }
                            } catch (e) {
                              Get.snackbar(
                                  "Error", "Failed to delete ${file.path}");
                            }
                          }
                          fileController.clearAllItems();
                          fileController
                              .listFiles(fileController.currentDirectory.value);
                          Get.snackbar("Success", "Selected items deleted.");
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
            appBar: AppBar(
              leading: Obx(() => Visibility(
                    visible: fileController.canGoBack.value,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        fileController.goBackDirectory();
                      },
                    ),
                  )),
              title: const Text("File Manager"),
              actions: [
                Obx(
                  () => mainFeatures(
                      context, fileController.currentDirectory.value),
                )
              ],
            ),
            body: mainScreen(fileController, searchController, context)),
        onWillPop: () async {
          if (fileController.canGoBack.value) {
            fileController.goBackDirectory();
            return false; // prevent app from closing
          }
          return true;
        });
  }

  //this is the Main Screen  of the App
  Widget mainScreen(FileBrowserController fileController,
      TextEditingController searchController, BuildContext context) {
    return Obx(() {
      final files = fileController.filteredFiles;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                // Implement search functionality here
                fileController.updateSearch(value);
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    fileController.updateSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() => buildBreadcrumbBar(fileController)),
          ),
          const Divider(),
          Obx(() {
            if (fileController.refreshValue.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Expanded(
              child: fileController.refreshValue.value
                  ? const Center(child: CircularProgressIndicator())
                  : files.isEmpty
                      ? const Center(child: Text("No files found"))
                      : fileController.isGridView.value
                          ? GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                return buildFileCardGrid(files[index], context,
                                    searchController.text);
                              },
                            )
                          : ListView.builder(
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                return buildFileCard(files[index], context,
                                    searchController.text, index);
                              },
                            ),
            );
          })
        ],
      );
    });
  }

// This is for the Grid View
  Widget buildFileCardGrid(dynamic entity, BuildContext context, String query) {
    final dbHelper = FavoriteDBHelper();
    return GestureDetector(
      onTap: () async {
        bool allowed = await ProtectionManager.validatePasswordIfProtected(
            context, entity.path);
        if (allowed) {
          fileController.openDirectory(entity, context);
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      fileController.isSelectionMode.value
                          ? Checkbox(
                              value:
                                  fileController.selectedItems.contains(entity),
                              onChanged: (_) =>
                                  fileController.toggleItemSelection(entity),
                            )
                          : Icon(
                              entity is Directory
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              size: 48,
                              color: Colors.blueAccent),
                      featuresOption(context, entity),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(highlightMatch(
                         p.basename(entity.path), query)),
                      IconButton(
                          onPressed: () {
                            dbHelper.addFavorite(entity.path);
                          },
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ))
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text("Type: ${entity is Directory ? "Folder" : "File"}"),
                Text("Size: ${fileController.getFileSize(entity)}"),
                Text(
                    "Modified: ${DateFormat('dd-MM-yyyy HH:mm a').format(entity.statSync().modified)}"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the file card based on the type of file
  Widget buildFileCard(dynamic entity, BuildContext context, String query  ,int index ) {
    final dbHelper = FavoriteDBHelper();
    return Card(
        child: Obx(
      () => GestureDetector(
        onLongPress:(){
          fileController.enableSelectionModeIfNeeded(); // don't toggle every time
          fileController.toggleItemSelection(entity);   // this checks/unchecks correctly
        } ,
        child: ListTile(
            leading: fileController.isSelectionMode.value
                ? Checkbox(
                    value: fileController.selectedItems.contains(fileController.fileName[index]),
                    onChanged: (_) => fileController.toggleItemSelection(entity),
                  )
                : Icon(
                    entity is Directory ? Icons.folder : Icons.insert_drive_file,
                    color: Colors.blue.shade700),
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text.rich(
                    highlightMatch(p.basename(entity.path), query),
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                      onPressed: () {
                        dbHelper.addFavorite(entity.path);
                      },
                      icon: Icon(
                        Icons.favorite,
                        color: Colors.red.shade700,
                      ))
                ],
              ),
            ),
            subtitle: Text(
                '	Type:${entity is Directory ? "Folder" : "File"})} ${fileController.getFileSize(entity)} • ${DateFormat('dd-MM-yyyy HH:mm a').format(entity.statSync().modified)}}'),
            onTap: () async {
              bool allowed = await ProtectionManager.validatePasswordIfProtected(
                  context, entity.path);
              if (allowed) {
                fileController.openDirectory(
                    entity, context); // Your existing open logic
              }
            },
            trailing: featuresOption(context, entity) // Handle more options here
            ),
      ),
    ));
  }

  //for the features of the file manager
  Widget mainFeatures(BuildContext context, FileSystemEntity entity) {
    return fileController.isSelectionMode.value
        ? IconButton(
            onPressed: () {
              fileController.clearAllItems();
            },
            icon: Icon(Icons.close))
        : PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == "layout") {;
                fileController.toggleView(); //This is for toggling of layout of the file manager
              }
              if (value == "Sort by") {
                showSortOptions(context, 'Name A → Z');
              }
              if (value == "Create New Folder") {
                fileController.showCreateFolderDialog(context);
              }
              if (value == "theme") {
                fileController.toggleTheme(); //This is for toggling of theme of the file manager
              }
              if (value == "Favorite") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FavoriteScreen()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'layout',
                child: Obx(() => Text(
                    '${fileController.isGridView.value ? "Switch to List View" : "Switch to Grid View"}')),
              ),
              PopupMenuItem(
                  value: 'theme',
                  child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(fileController.isDarkTheme.value
                              ? "Switch to Light"
                              : "Switch to Dark "),
                          Icon(fileController.isDarkTheme.value
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round),
                        ],
                      ))),
              const PopupMenuItem<String>(
                value: 'Sort by',
                child: Text('Sort by'),
              ),
              const PopupMenuItem<String>(
                value: 'Create New Folder',
                child: Text('Create New Folder'),
              ),
              const PopupMenuItem(
                child: Text('Favorite Files & Folders'),
                value: 'Favorite',
              )
            ],
          );
  }

  //for the features option Share, copy , delete , rename, properties etc
  Widget featuresOption(BuildContext context, FileSystemEntity entity) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetItem(context, 'Open', Icons.open_in_new, () {
                  Navigator.pop(context); // Close sheet
                  fileController.openFile(entity, context);
                }),
                _buildSheetItem(context, 'Share', Icons.share, () {
                  Navigator.pop(context);
                  fileController.shareFile(context, entity);
                }),
                _buildSheetItem(context, 'Copy', Icons.copy, () {
                  Navigator.pop(context);
                  fileController.initiateMoveOrCopySingle(entity, "copy");
                }),
                _buildSheetItem(context, 'Move', Icons.drive_file_move, () {
                  Navigator.pop(context);
                  fileController.initiateMoveOrCopySingle(entity, "move");
                }),
                _buildSheetItem(context, 'Delete', Icons.delete, () {
                  Navigator.pop(context);
                  fileController.showDeleteDialog(context, entity);
                }),
                _buildSheetItem(context, 'Rename', Icons.edit, () {
                  Navigator.pop(context);
                  fileController.renameFileOrFolder(context, entity);
                }),
                _buildSheetItem(context, 'Protection', Icons.lock, () async {
                  Navigator.pop(context);
                  await ProtectionManager.setPassword(context, entity.path);
                }),
              ],
            );
          },
        );
      },
    );
  }
  /// Helper widget for bottom sheet item and set the  content of bottom sheet
  Widget _buildSheetItem(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

//This is for the Showing sort Options for the file manager
void showSortOptions(BuildContext context, String selectedOption) {
  final fileController = Get.find<FileBrowserController>();
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  sortRadioOption(
                    'Name A → Z',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context); // Close modal immediately
                    },
                  ),
                  sortRadioOption(
                    'Name Z → A',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context);
                    },
                  ),
                  sortRadioOption(
                    'Largest first',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context);
                    },
                  ),
                  sortRadioOption(
                    'Smallest first',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context);
                    },
                  ),
                  sortRadioOption(
                    'Newest date first',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context);
                    },
                  ),
                  sortRadioOption(
                    'Oldest date first',
                    selectedOption,
                    (value) {
                      setState(() => selectedOption = value);
                      fileController.sortFilesByOption(value);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

//This is the Widget of the sortRadioOption
Widget sortRadioOption(
  String option,
  String selectedOption,
  ValueChanged<String> onChanged,
) {
  return RadioListTile<String>(
    title: Text(option),
    value: option,
    groupValue: selectedOption,
    onChanged: (value) {
      if (value != null) {
        onChanged(value);
      }
    },
  );
}

//This is the Widget of the buildBreadCrumbed
Widget buildBreadcrumbBar(FileBrowserController controller) {
  final segments =
      controller.getPathSegments(controller.currentDirectory.value.path);
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal, // Set horizontal scroll
    child: Row(
      children: List.generate(segments.length, (index) {
        final segment = segments[index];
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                final targetPath = segment['path'];
                if (targetPath != null && Directory(targetPath).existsSync()) {
                  controller.listFiles(Directory(targetPath));
                } else {
                  Get.snackbar(
                      "Error", "Folder does not exist or path is invalid");
                }
              },
              child: Text(
                segment['name']!,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (index != segments.length - 1)
              const Icon(Icons.chevron_right, size: 18),
          ],
        );
      }),
    ),
  );
}

//it is helper class for helping the operation of copy ,move and delete
Widget _buildActionButton({
  required IconData icon,
  required String label,
  required String heroTag,
  required VoidCallback onPressed,
}) {
  return FloatingActionButton.extended(
    heroTag: heroTag,
    icon: Icon(icon),
    label: Text(label),
    onPressed: onPressed,
  );
}
