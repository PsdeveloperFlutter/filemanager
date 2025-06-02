import 'dart:io';
import 'package:filemanager/categoriesScreen.dart';
import 'package:filemanager/main.dart';
import 'package:filemanager/passwordProtection.dart';
import 'package:filemanager/recentFiles.dart';
import 'package:filemanager/sqfliteDatabase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'fileBrowserController.dart';

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
      onWillPop: () async {
        if (fileController.canGoBack.value) {
          fileController.goBackDirectory();
          return false; // Prevent closing app
        }
        return true;
      },
      child: Scaffold(
        drawer: buildMainFeaturesDrawer(context),
        body: mainScreen(fileController, searchController, context),
        floatingActionButton: Obx(() {
          if (!fileController.isSelectionMode.value ||
              fileController.selectedItems.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.extended(
                  heroTag: "copy",
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy"),
                  onPressed: () {
                    fileController.initiateMoveOrCopyMultiple(
                        fileController.selectedItems, "copy", context);
                  },
                ),
                FloatingActionButton.extended(
                  heroTag: "move",
                  icon: const Icon(Icons.drive_file_move),
                  label: const Text("Move"),
                  onPressed: () {
                    fileController.initiateMoveOrCopyMultiple(
                        fileController.selectedItems, "move", context);
                  },
                ),
                FloatingActionButton.extended(
                  heroTag: "delete",
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
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
                      deleteSelectedItems(context);
                    }
                  },
                ),
              ],
            ),
          );
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  //This is the logic of confirm delete
  void deleteSelectedItems(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content:
            const Text("Are you sure you want to delete the selected items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final file in fileController.selectedItems) {
        try {
          if (file.existsSync()) {
            file.deleteSync(recursive: true);
          }
        } catch (e) {
          Get.snackbar("Error", "Failed to delete ${file.path}");
        }
      }

      fileController.clearAllItems();
      fileController.listFiles(fileController.currentDirectory.value);
      Get.snackbar("Success", "Selected items deleted.");
    }
  }

  Widget mainScreen(FileBrowserController fileController,
      TextEditingController searchController, BuildContext context) {
    return Obx(() {
      final files = fileController.filteredFiles;

      return CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) => TextField(
                    controller: searchController,
                    onChanged: (value) => fileController.updateSearch(value),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8),
                      hintText: 'Search',
                      prefixIcon: Obx(() {
                        if (fileController.isSelectionMode.value) {
                          return IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              fileController
                                  .clearAllItems(); // Clear selected items// Exit selection mode
                            },
                          );
                        }
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        );
                      }),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          fileController.updateSearch('');
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Breadcrumb Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: buildBreadcrumbBar(fileController),
            ),
          ),
          // Recent Files
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "Recent Files",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                    height: 165, child: RecentFilesScreen(key: recentFilesKey)),
              ],
            ),
          ),
          // Files List or Grid
          if (fileController.refreshValue.value)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (files.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No files found"),
              )),
            )
          else if (fileController.isGridView.value)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return buildFileCardGrid(
                      files[index],
                      context,
                      searchController.text,
                    );
                  },
                  childCount: files.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return buildFileCard(
                    files[index],
                    context,
                    searchController.text,
                    index,
                  );
                },
                childCount: files.length,
              ),
            ),

          // Categories
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text("Categories",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(
                  height: 7,
                ),
                CategoriesScreen(),
              ],
            ),
          ),
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
          if (entity is Directory) {
            fileController.listFiles(entity); // Update directory
            insertRecentFile(entity); // Insert recent directory
          } else {
            insertRecentFile(entity); // Insert recent file
          }
          fileController.clearAllItems(); // Clear selectiontory.value);
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
                      Text.rich(highlightMatch(p.basename(entity.path), query)),
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
  Widget buildFileCard(
      dynamic entity, BuildContext context, String query, int index) {
    final dbHelper = FavoriteDBHelper();
    return Card(
        child: Obx(
      () => GestureDetector(
        onLongPress: () {
          fileController
              .enableSelectionModeIfNeeded(); // don't toggle every time
          fileController
              .toggleItemSelection(entity); // this checks/unchecks correctly
        },
        child: ListTile(
            leading: fileController.isSelectionMode.value
                ? Checkbox(
                    value: fileController.selectedItems
                        .contains(fileController.fileName[index]),
                    onChanged: (_) =>
                        fileController.toggleItemSelection(entity),
                  )
                : Icon(
                    entity is Directory
                        ? Icons.folder
                        : Icons.insert_drive_file,
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
                "Modified: ${DateFormat('dd-MM-yyyy HH:mm a').format(entity.statSync().modified)}"),
            onTap: () async {
              bool allowed =
                  await ProtectionManager.validatePasswordIfProtected(
                      context, entity.path);
              if (allowed) {
                openFileWithIntent(
                    entity.path, context); // Your existing open logic
              }
            },
            trailing:
                featuresOption(context, entity) // Handle more options here
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
        : Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                buildMainFeaturesDrawer(context);
              },
            ),
          );
  }

  Drawer buildMainFeaturesDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'File Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.view_list,
              color: Colors.purpleAccent,
            ),
            title: Obx(() => Text(
                '${fileController.isGridView.value ? "Switch to List View" : "Switch to Grid View"}')),
            onTap: () {
              fileController.toggleView();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Obx(() => Icon(
                  fileController.isDarkTheme.value
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_round,
                  color: fileController.isDarkTheme.value
                      ? Colors.yellow
                      : Colors.grey,
                )),
            title: Obx(() => Text(fileController.isDarkTheme.value
                ? "Switch to Light"
                : "Switch to Dark ")),
            onTap: () {
              fileController.toggleTheme();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.sort,
              color: Colors.blue.shade700,
            ),
            title: Text('Sort by'),
            onTap: () {
              Navigator.pop(context);
              showSortOptions(context, 'Name A → Z');
            },
          ),
          ListTile(
            leading: Icon(Icons.create_new_folder, color: Colors.purpleAccent),
            title: Text('Create New Folder'),
            onTap: () {
              Navigator.pop(context);
              fileController.showCreateFolderDialog(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            title: Text('Favorite Files & Folders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoriteScreen()),
              );
            },
          ),
        ],
      ),
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
                _buildSheetItem(context, 'Open', Icons.open_in_new, () async {
                  Navigator.pop(context); // Close sheet
                  openFileWithIntent(entity.path, context); // Open file
                  insertRecentFile(entity); // Insert recent file
                }),
                _buildSheetItem(context, 'Share', Icons.share, () {
                  Navigator.pop(context);
                  fileController.shareFile(context, entity);
                }),
                _buildSheetItem(context, 'Copy', Icons.copy, () {
                  Navigator.pop(context);
                  fileController.initiateMoveOrCopySingle(
                      entity, "copy", context);
                }),
                _buildSheetItem(context, 'Move', Icons.drive_file_move, () {
                  Navigator.pop(context);
                  fileController.initiateMoveOrCopySingle(
                      entity, "move", context);
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

//This is the function Responsible for the Inserting Recent Files
void insertRecentFile(FileSystemEntity entity) {
  Map<String, dynamic> fileDetails = {
    'name': p.basename(entity.path),
    'path': entity.path,
    'type': entity is Directory ? 'directory' : 'file',
  };
  recentFilesKey.currentState?.insertFile(fileDetails);
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
