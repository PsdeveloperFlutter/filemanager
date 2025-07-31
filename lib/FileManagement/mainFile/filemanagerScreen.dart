// This is the Code For the File Manager Sub Screen
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';

import '../projectSetting/AuthService.dart';

class FileManagerScreenSub extends StatefulWidget {
  final String path;

  const FileManagerScreenSub({super.key, required this.path});

  @override
  State<FileManagerScreenSub> createState() => FileManagerScreenSubState();
}

class FileManagerScreenSubState extends State<FileManagerScreenSub> {
  bool isSelectionMode = false;
  List<FileSystemEntity> selectedItems = [];
  List<FileSystemEntity> currentlyDraggingItems = [];
  bool isDragging = false;
  AuthService authService = AuthService();

  List<FileSystemEntity> allItems = [];
  String? hoverTargetPath;
  bool isGridView = false;
  bool isDragg = false;

  @override
  void initState() {
    super.initState();
    fetchFolderContent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  //For Fetching the Folders
  void fetchFolderContent() {
    final dir = Directory(widget.path);
    if (dir.existsSync()) {
      List<FileSystemEntity> items = dir.listSync();

      items.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        allItems = items;
        selectedItems.clear();
      });
    }
  }



  Future<void> handleDrop(String targetPath,
      List<FileSystemEntity> draggedItems, BuildContext context) async {
    await Future.wait(draggedItems.map((item) async {
      final newPath = '$targetPath/${basename(item.path)}';
      try {
        if (await FileSystemEntity.type(newPath) ==
            FileSystemEntityType.notFound) {
          await item.rename(newPath);
        }
      } catch (e) {
        debugPrint("Error moving file: $e");
      }
    }));
    fetchFolderContent();
    setState(() {
      selectedItems.clear();
      isSelectionMode = false;
    });
  }

  Future<void> movesFileToFolder(
      List<FileSystemEntity> files,
      Directory targetFolder,
      BuildContext context,
      int len,
      Directory item
      ) async {
    for (final file in files) {
      try {
        final filename = basename(file.path);
        final newPath = join(targetFolder.path, filename);
        await file.rename(newPath);
        Future.delayed(Duration(milliseconds: 1000),(){
        return  fetchFolderContent();
        });
        Flushbar(
          title: 'Successfully',
          message: len == 0
              ? '${len + 1} Document Move Successfully'
              : len == 1
              ? ' $len Document Move Successfully'
              : '$len Documents Move Successfully',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orangeAccent,
          icon: Icon(
            Icons.check,
            color: Colors.black,
          ),
        );
      } catch (e) {
        debugPrint("Error moving file: $e");
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () =>createFolder(context,widget.path),
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        appBar: AppBar(
          title: isSelectionMode == false
              ? Text(widget.path.split("/").last)
              : GestureDetector(
              onTap: () {
                setState(() {
                  isSelectionMode = false;
                  selectedItems.clear();
                });
              },
              child: Icon(
                Icons.cancel,
                color: Colors.green,
              )),
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    isGridView = !isGridView;
                  });
                },
                icon: Icon(isGridView ? Icons.list : Icons.grid_view)),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          if (allItems.isEmpty) {
            return Center(
                child: Text(
                  "No Files or Folder Available ",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ));
          }
          final isLandScape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          return isGridView
              ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandScape ? 4 : 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: allItems.length,
              itemBuilder: (context, index) => SizedBox(
                  height: 80,
                  width: 80,
                  child: buildDraggableItems(index, context)))
              : ListView.builder(
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              return buildDraggableItems(index, context);
            },
          );
        }));
  }



  //This Below Code is for the Drag and Drop Functionality of the File Manager
  Widget buildDraggableItems(int index, BuildContext context) {
    final item = allItems[index];
    final isFolder = item is Directory;
    final isSelected = selectedItems.any((e) => e.path == item.path);

    return DragTarget<List<FileSystemEntity>>(
      onWillAcceptWithDetails: (dragged) => isFolder,
      onAccept: (dragged) async {
        if (isFolder) {
          await movesFileToFolder(
              dragged, item, context, selectedItems.length, item);
          setState(() {
            selectedItems.clear();
            isSelectionMode = false;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return LongPressDraggable<List<FileSystemEntity>>(
          data: selectedItems.isEmpty ? [item] : selectedItems,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              height: 40,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "${selectedItems.isEmpty ? 1 : selectedItems.length} File${(selectedItems.length <= 1) ? '' : 's'}",
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            setState(() {
              isDragging = true;
            });
            print(
                "Drag started with: ${selectedItems.map((e) => e.path).toList()}");
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              selectedItems.clear();
              isSelectionMode = false;
              isDragg = false;
            });
          },
          onDragEnd: (_) {
            setState(() {
              isDragging = false;
              isDragg = false;
            });
          },
          child: AnimatedScale(
            filterQuality: FilterQuality.high,
            scale: (isDragging && isSelected) ? 1.10 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Card(
              elevation: 1,
              color: isHighlighted && isFolder
                  ? Colors.greenAccent.shade200
                  : Colors.white,
              child: SizedBox(
                width: 40,
                child: ListTile(
                  onTap: () {
                    if (isSelectionMode && !isFolder) {
                      setState(() {
                        if (isSelected) {
                          selectedItems.removeWhere((e) => e.path == item.path);
                        } else {
                          selectedItems.add(item);
                        }
                      });
                    } else if (isFolder) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FileManagerScreenSub(path: item.path),
                        ),
                      );
                    } else {
                      OpenFilex.open(item.path); // ✅ Open file on tap
                    }
                  },
                  onLongPress: !isSelectionMode && !isFolder
                      ? () {
                    setState(() {
                      isSelectionMode = true;
                      if (!isSelected) {
                        selectedItems.add(item);
                      }
                    });
                  }
                   :null,
                  leading: isSelectionMode && !isFolder
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedItems.add(item);
                        } else {
                          selectedItems
                              .removeWhere((e) => e.path == item.path);
                        }
                      });
                    },
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Icon(
                      isFolder ? Icons.folder : Icons.insert_drive_file,
                      color: Colors.green,
                      size: 25,
                    ),
                  ),
                  title: Text(
                    basename(item.path),
                    style: TextStyle(
                      fontWeight: (isSelected && isSelectionMode)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: (isSelected && isSelectionMode)
                          ? Colors.blue
                          : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    isFolder ? 'Folder' : 'File',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //Code for Creating a Folder
  Future<void> createFolder(BuildContext context,path) async {
    TextEditingController folderNameController = TextEditingController();
    String? errorText; // For feedback inside the dialog
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                  title: Text("Create a New Folder"),
                  content: TextField(
                    controller: folderNameController,
                    decoration: InputDecoration(
                      hintText: "Enter Folder Name",
                      errorText: errorText,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        folderNameController.clear();
                        Navigator.of(context).pop();
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String newFolderName =
                        folderNameController.text.trim();
                        if (newFolderName.isNotEmpty) {
                          final folder =
                          Directory("$path/$newFolderName");
                          if (!await folder.exists()) {
                            await folder.create();
                            fetchFolderContent();
                            folderNameController.clear();
                            Navigator.of(context).pop();
                          } else {
                            uiObject.flushBars("Error", "Error Occur",
                                Colors.red, context);
                          }
                        }
                      },
                      child: Text("Create"),
                    )
                  ]));
        });
  }

}
