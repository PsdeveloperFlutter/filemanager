import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FileManagerScreen(),
  ));
}

class FileManagerScreen extends StatefulWidget {
  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileSystemEntity> allItems = [];

  @override
  void initState() {
    super.initState();
    requestPermissionAndFetch();
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
      appBar: AppBar(
        title: Text("File Manager"),
      ),
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
  List<FileSystemEntity> allItems = [];
  String? hoverTargetPath;

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
      });
    }
  }

  Future<void> handleDrop(String targetPath, FileSystemEntity draggedItem,
      BuildContext context) async {
    try {
      final newPath = '$targetPath/${basename(draggedItem.path)}';
      await draggedItem.rename(newPath);
      fetchFolderContent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Moved to ${basename(targetPath)}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to move: $e")),
      );
    }
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
      ),
      body: ListView.builder(
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          final isFolder = item is Directory;

          return DragTarget<FileSystemEntity>(
              onWillAccept: (dragged) {
                if (isFolder && dragged!.path != item.path) {
                  setState(() {
                    hoverTargetPath = item.path;
                  });
                  return true;
                }
                return false;
              },
              onLeave: (_) => setState(() => hoverTargetPath = null),
              onAccept: (dragged) {
                setState(() => hoverTargetPath = null);
                handleDrop(item.path, dragged, context);
              },
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.grey.withOpacity(0.7),
                      child: Text(item.path.split("/").last,
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  child: Container(
                    color: hoverTargetPath == item.path
                        ? Colors.blue.withOpacity(0.2)
                        : null,
                    child: Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                            isFolder ? Icons.folder : Icons.insert_drive_file,
                            color: Colors.green),
                        title: Text(item.path.split("/").last),
                        subtitle: Text(isFolder ? "Folder" : "File"),
                        onTap: () {
                          if (!isFolder) {
                            OpenFilex.open(item.path);
                          }
                          if (isFolder) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FileManagerScreenSub(path: item.path),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              });
        },
      ),
    );
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
}
