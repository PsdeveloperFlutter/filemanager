import 'dart:io';

import 'package:filemanager/FileManagement/AuthService.dart';
import 'package:filemanager/FileManagement/LockScreen.dart';
import 'package:flutter/material.dart';
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

  const FileManagerScreenSub({required this.path});

  @override
  State<FileManagerScreenSub> createState() => _FileManagerScreenSubState();
}

class _FileManagerScreenSubState extends State<FileManagerScreenSub> {
  bool isSelectionMode = false;
  Set<FileSystemEntity> selectedItems = {};
  List<FileSystemEntity> currentlyDraggingItems = [];

  List<FileSystemEntity> allItems = [];
  String? hoverTargetPath;
  bool isGridView = false;
  bool isDragging = false;

  void initState() {
    super.initState();
    fetchFolderContent();
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
        isSelectionMode=false;
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
          title: Text("${widget.path.split("/").last}"),
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
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) =>
                      buildDraggableItems(index, context))
              : ListView.builder(
                  itemCount: allItems.length,
                  itemBuilder: (context, index) =>
                      buildDraggableItems(index, context),
                );
        }));
  }

  void CreateFolder(BuildContext context) {
    TextEditingController folderNameController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("Create a New Folder"),
              content: TextField(
                controller: folderNameController,
                decoration: InputDecoration(hintText: "Enter Folder Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    String NewFolderName = folderNameController.text.trim();
                    if (NewFolderName.isNotEmpty) {
                      final Folder = Directory("${widget.path}/$NewFolderName");
                      if (!await Folder.exists()) {
                        await Folder.create();
                        fetchFolderContent();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Folder '$NewFolderName' created")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Folder already exists")),
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Create"),
                )
              ]);
        });
  }

  static const double gridItemHeight = 50.0;
  static const double listItemHeight = 85.0;

  Widget buildDraggableItems(int index, BuildContext context) {
    final item = allItems[index];
    final isFolder = item is Directory;
    final itemName = basename(item.path);
    final isSelected = selectedItems.any((e) => e.path == item.path);

    return DragTarget<List<FileSystemEntity>>(
      onWillAccept: (draggedItems) {
        if (isFolder && draggedItems != null && !draggedItems.any((e) => e.path == item.path)) {
          setState(() => hoverTargetPath = item.path);
          return true;
        }
        return false;
      },
      onLeave: (_) => setState(() => hoverTargetPath = null),
      onAcceptWithDetails: (draggedItems) {
        setState(() => hoverTargetPath = null);
        final itemsToDrop = List<FileSystemEntity>.from(draggedItems.data);
        handleDrop(item.path, itemsToDrop, context);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<List<FileSystemEntity>>(
          data: selectedItems.isEmpty ? [item] : selectedItems.toList(),
          feedback: _buildDragFeedback(itemName),
          onDragStarted: () {
            setState(() {
              if (selectedItems.isEmpty) selectedItems.add(item);
              isDragging = true;
            });
          },
          onDragEnd: (_) {
            setState(() => isDragging = false);
          },
          onDraggableCanceled: (_, __) {
            setState(() => isDragging = false);
          },
          child: GestureDetector(
            onTap: () => _toggleSelection(item),
            child: _buildDraggableTile(item, isFolder, itemName, isSelected,context),
          ),
        );
      },
    );
  }

  void _toggleSelection(FileSystemEntity item) {
    setState(() {
      final exists = selectedItems.any((e) => e.path == item.path);
      if (exists) {
        selectedItems.removeWhere((e) => e.path == item.path);
      } else {
        selectedItems.add(item);
      }
    });
  }

  Widget _buildDragFeedback(String itemName) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.black87,
        child: Text(
          selectedItems.length > 1 ? "${selectedItems.length} items" : itemName,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDraggableTile(FileSystemEntity item, bool isFolder, String itemName, bool isSelected,BuildContext context) {
    return Container(
      height: isGridView ? gridItemHeight : listItemHeight,
      color: hoverTargetPath == item.path
          ? Colors.blue.withOpacity(0.2)
          : isSelected
          ? Colors.green.withOpacity(0.4)
          : null,
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            isFolder ? Icons.folder : Icons.insert_drive_file,
            color: Colors.green,
          ),
          title: Text(itemName),
          subtitle: Text(isFolder ? "Folder" : "File"),
          onTap: () {
            if (isFolder) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FileManagerScreenSub(path: item.path),
                ),
              );
            } else {
              OpenFilex.open(item.path);
            }
          },
        ),
      ),
    );
  }
}
