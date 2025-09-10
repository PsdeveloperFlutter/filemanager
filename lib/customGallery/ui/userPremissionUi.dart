import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../settings/customGallerySetting.dart';
import 'customGalleryUi.dart';

void main() {
  runApp(MaterialApp(
    home: FilePermissionScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

final settings=CustomGallerySetting();
class FilePermissionScreen extends StatefulWidget {

  FilePermissionScreen({super.key});

  @override
  State<FilePermissionScreen> createState() => _FilePermissionScreenState();
}

class _FilePermissionScreenState extends State<FilePermissionScreen> {
  List<File> files = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with proper color and icon
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62), // Dark blue color like in UI
        title: const Text(
          "File Permission",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: ()=>settings.pickFilesFromSystemWithAutoFolder(setState ,files,context),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Section
            Center(
              child: Image.asset(
                'assets/images/UiImage.png', // Add the image to assets folder
                height: 180,
                width: 180,
              ),
            ),
            const SizedBox(height: 20),

            // Text Description
            const Text(
              "Allow File Permission to use Doc Scanner's InApp File.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 25),

            // Allow File Permission Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _handlePermissionRequest(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:Colors.blue.shade700, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "ALLOW FILE PERMISSION",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text("Or Use", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            // System File Button
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () =>settings.pickFilesFromSystemWithAutoFolder(setState ,files,context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:  const Color(0xFF0A3D62), // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "SYSTEM FILE",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePermissionRequest(BuildContext context) async {
    // Request permission
    bool granted = await settings.requestStoragePermission();
    if (granted) {
    Navigator.pop(context);
    Future.delayed(Duration(milliseconds: 200),(){
      Navigator.push(context,MaterialPageRoute(builder: (context) => CustomGalleryApp()));
    });

    } else {
      // Show dialog if permission is denied
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permission Denied"),
          content: const Text("Please grant storage permission to use this feature."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
}

