import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner:false,
    home: FileManagerScreen(),));
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
                  leading:
                      Icon(isFolder ? Icons.folder : Icons.insert_drive_file,color: Colors.green,),
                  title: Text(item.path.split("/").last),
                  subtitle: Text(isFolder ? "Folder" : "File"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                FileManagerScreenSub(path: item.path)));
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
  String ?hoverTargetPath;

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
  Future<void>handleDrop(String targetPath,FileSystemEntity draggedItem,BuildContext context)async{
    try{
      final newPath='$targetPath/${basename(draggedItem.path)}';
      await draggedItem.rename(newPath);
      fetchFolderContent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Moved to ${basename(targetPath)}")),
      );
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to move: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.path.split("/").last}"),
      ),
      body: ListView.builder(
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          final isFolder = item is Directory;

          return DragTarget<FileSystemEntity>(
              onWillAccept: (dragged){
                if(isFolder && dragged!.path!=item.path){
                  setState(() {
                    hoverTargetPath=item.path;
                  });
                  return true;
                }
                return false;
              },
              onLeave: (_)=>setState(()=>hoverTargetPath=null),
              onAccept:(dragged){
                setState(() => hoverTargetPath = null);
                handleDrop(item.path, dragged,context);
              },
              builder:(context,candidateData,rejectedData){
                return  LongPressDraggable(data :item,child: Container(
                  color: hoverTargetPath == item.path ? Colors.blue.withOpacity(0.2) : null,
                  child: ListTile(
                    leading: Icon(isFolder?Icons.folder:Icons.insert_drive_file),
                    title: Text(item.path),
                    subtitle: Text(isFolder ? "Folder" : "File"),
                    onTap: (){
                      if(isFolder){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FileManagerScreenSub(path: item.path),
                          ),
                        );
                      }
                    },

                  ),
                ), feedback:

                Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.grey.withOpacity(0.7),
                    child: Text(item.path, style: TextStyle(color: Colors.white)),
                  ),
                ),);
              } );
        },
      ),
    );
  }
}
