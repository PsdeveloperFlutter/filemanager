import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';

class FileManagerPage extends StatefulWidget {
  final String initialPath;

  const FileManagerPage({Key? key, required this.initialPath})
      : super(key: key);

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  late Directory currentDir;
  late List<FileSystemEntity> allItems;
  List<FileSystemEntity> selectedItems = [];
  bool selectionMode = false;

  @override
  void initState() {
    super.initState();
    currentDir = Directory(widget.initialPath);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      allItems = currentDir.listSync();
      selectedItems.clear();
      selectionMode = false;
    });
  }

  Future<void> moveFilesToFolder(
      List<FileSystemEntity> files, Directory targetFolder) async {
    for (final file in files) {
      try {
        final fileName = basename(file.path);
        final newPath = join(targetFolder.path, fileName);
        await file.rename(newPath);
      } catch (e) {
        print('Error moving file ${file.path} to $targetFolder: $e');
      }
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDir.path),
        actions: [
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  selectionMode = false;
                  selectedItems.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allItems.length,
        itemBuilder: (context, idx) {
          final item = allItems[idx];
          final isSelected = selectedItems.any((e) => e.path == item.path);
          final isFolder = item is Directory;

          return DragTarget<List<FileSystemEntity>>(
            onWillAccept: (dragged) => isFolder,
            onAccept: (dragged) async {
              if (isFolder) {
                await moveFilesToFolder(dragged!, item as Directory);
                setState(() {
                  selectedItems.clear();
                  selectionMode = false;
                });
              }
            },
            builder: (context, _, __) {
              return Row(
                children: [
                  selectionMode
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(isFolder
                              ? Icons.folder
                              : Icons.insert_drive_file),
                        ),
                  Expanded(
                    child: Draggable<List<FileSystemEntity>>(
                      data: selectedItems.isEmpty ? [item] : selectedItems,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black87,
                          child: Text(
                            '${selectedItems.isEmpty ? 1 : selectedItems.length} file${(selectedItems.length == 1 || selectedItems.isEmpty) ? '' : 's'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (selectionMode) {
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
                                builder: (_) =>
                                    FileManagerPage(initialPath: item.path),
                              ),
                            );
                          } else {
                            OpenFilex.open(item.path);
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            selectionMode = true;
                            if (!selectedItems
                                .any((e) => e.path == item.path)) {
                              selectedItems.add(item);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(basename(item.path)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FileManagerPage(
        initialPath:
            "/storage/emulated/0"), // Set to a valid directory for your platform
  ));
}
