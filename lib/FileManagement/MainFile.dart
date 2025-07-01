import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager/FileManagement/AuthService.dart';
import 'package:filemanager/FileManagement/LockScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Setting.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

//This is the Code For the Starting of the App
class MyApp extends StatelessWidget {
  final _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.wait([
          _authService.GetPin(),
          _authService.isAppLockEnabled(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final String? pin = snapshot.data?[0];
          final bool isAppLockEnabled = snapshot.data?[1] ?? false;
          print("PIN: $pin");
          print("isAppLockEnabled: $isAppLockEnabled");
          if (pin == null) {
            return FileManagerScreen();
          }

          if (!isAppLockEnabled) {
            return FileManagerScreen();
          }

          // ✅ Use callback to unlock
          return LockScreen();
        },
      ),
    );
  }
}

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen>
    with WidgetsBindingObserver {
  bool shouldLock = false;
  List<FileSystemEntity> allItems = [];

  @override
  void initState() {
    super.initState();
    requestPermissionAndFetch();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifeCycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      shouldLock = true;
    }
    if (state == AppLifecycleState.resumed && shouldLock) {
      shouldLock = false;
      _lockapp(context as BuildContext);
    }
  }

  _lockapp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LockScreen()),
    );
  }

  //request permission and fetch
  void requestPermissionAndFetch() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      final dir = Directory("/storage/emulated/0");
      if (await dir.exists()) {
        List<FileSystemEntity> items = dir.listSync();
        //sort Folders First
        items.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
        setState(() {
          allItems = items;
        });
      }
    } else {
      openAppSettings(); //open app settings
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("File Manager"), actions: [
        IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return MyHomePage(); //AppLockSettingsScreen();
              }));
            },
            icon: Icon(Icons.settings))
      ]),
      body: ListView.builder(
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            final isFolder = item is Directory;
            return Card(
              elevation: 2,
              child: ListTile(
                  leading: Icon(
                    isFolder ? Icons.folder : Icons.insert_drive_file,
                    color: Colors.green,
                  ),
                  title: Text(item.path.split("/").last),
                  subtitle: Text(isFolder ? "Folder" : "File"),
                  onTap: () {
                    if (!isFolder) {
                      // Open file using the OpenFilex package
                      OpenFilex.open(item.path);
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  FileManagerScreenSub(path: item.path)));
                    }
                  }),
            );
          }),
    );
  }
}

class FileManagerScreenSub extends StatefulWidget {
  final String path;

  const FileManagerScreenSub({super.key, required this.path});

  @override
  State<FileManagerScreenSub> createState() => _FileManagerScreenSubState();
}

class _FileManagerScreenSubState extends State<FileManagerScreenSub> {
  ScrollController _scrollController = ScrollController();
  bool isSelectionMode = false;
  List<FileSystemEntity> selectedItems = [];
  List<FileSystemEntity> currentlyDraggingItems = [];

  List<FileSystemEntity> allItems = [];
  String? hoverTargetPath;
  bool isGridView = false;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    fetchFolderContent();
  }

  void dispose() {
    super.dispose();
    _scrollController.dispose();
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
        print("Error moving file: $e");
      }
    }));
    fetchFolderContent();
    setState(() {
      selectedItems.clear();
      isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () => CreateFolder(context),
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
                  controller: _scrollController, // <-- attach here!
                  itemCount: allItems.length,
                  itemBuilder: (context, index) =>
                      buildDraggableItems(index, context),
                );
        }));
  }

  Future<void> CreateFolder(BuildContext context) async {
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
                            String NewFolderName =
                                folderNameController.text.trim();
                            if (NewFolderName.isNotEmpty) {
                              final folder =
                                  Directory("${widget.path}/$NewFolderName");
                              if (!await folder.exists()) {
                                await folder.create();
                                fetchFolderContent();
                                folderNameController.clear();
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  errorText = "Folder Already Exists";
                                });
                              }
                            }
                          },
                          child: Text("Create"),
                        )
                      ]));
        });
  }

  //This Below Code is for the Drag and Drop Functionality of the File Manager
  Widget buildDraggableItems(int index, BuildContext context) {
    final item = allItems[index];
    final isSelected = selectedItems.any((e) => e.path == item.path);
    final isFolder = item is Directory;

    return DragTarget<List<FileSystemEntity>>(
      onWillAccept: (dragged) => isFolder,
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
              decoration: BoxDecoration(
                color: Colors.orangeAccent.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              height: 40,
              width: 120,
              child: Center(
                child: Text(
                  "${selectedItems.isEmpty ? 1 : selectedItems.length} File${selectedItems.length == 1 || selectedItems.isEmpty ? '' : 's'}",
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            // Optionally set selection mode here
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              selectedItems.clear();
              isSelectionMode = false;
            });
          },
          child: Card(
            color: isHighlighted && isFolder
                ? Colors.greenAccent.shade200
                : Colors.white,
            elevation: 1,
            child: SingleChildScrollView(
              child: Container(
                height: 100,
                child: Row(
                  children: [
                    isSelectionMode && !isFolder
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Icon(
                              isFolder ? Icons.folder : Icons.insert_drive_file,
                              color: Colors.green,
                              size: 25,
                            ),
                          ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          OpenFilex.open(item.path);
                        },
                        child: ListTile(
                          subtitle: isFolder == true
                              ? Text("Folder")
                              : Text(
                                  "File",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15),
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
                            ),
                          ),
                          onTap: () {
                            if (isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  selectedItems
                                      .removeWhere((e) => e.path == item.path);
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
                                  ));
                            } else {
                              OpenFilex.open(item.path);
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              if (isFolder) {
                                isSelectionMode = false;
                              } else {
                                isSelectionMode = true;
                              }
                              if (!selectedItems
                                  .any((e) => e.path == item.path)) {
                                selectedItems.add(item);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> movesFileToFolder(
      List<FileSystemEntity> files,
      Directory targetFolder,
      BuildContext context,
      int len,
      Directory item) async {
    for (final file in files) {
      try {
        final filename = basename(file.path);
        final newPath = join(targetFolder.path, filename);
        await file.rename(newPath);
        Flushbar(
          title: 'Successfully',
          message: len == 0
              ? '${len + 1} Document Move Successfully'
              : len == 1
                  ? ' ${len} Document Move Successfully'
                  : '$len Documents Move Successfully',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orangeAccent,
          icon: Icon(
            Icons.check,
            color: Colors.black,
          ),
        ).show(context).then((_) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return FileManagerScreenSub(path: item.path);
          }));
        });
      } catch (e) {
        print("Error moving file: $e");
      }
    }
    fetchFolderContent(); //For Refresh the Folder
  }
}
