import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// inside your State class
final Map<String, ImageProvider> _pdfThumbCache = {};


/// Widget to display files in List or Grid View
Widget buildFilesView({
  required List<File> files,
  required List<File> importFiles,
  required bool isGridView, // ✅ Control whether Grid or List
  required Function(File) toggleFileSelection,
  required dynamic settings,
}) {
  // ✅ If no files, show a message
  if (files.isEmpty) {
    return const Center(child: Text("No Files Found"));
  }

  // ✅ LIST VIEW MODE
  if (!isGridView) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(height: 0.2, color:Colors.black12), // Divider between items
      padding: EdgeInsets.only(
        top: 0,
        bottom: 54.8  // Adjust padding for bottom import section
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        File file = files[index];
        String fileName = file.path.split('/').last;

        return Card(
          margin: EdgeInsets.zero, // Remove margin around the Card
          elevation: 2,
          child: ListTile(
            // contentPadding: EdgeInsets.zero,
            // visualDensity: VisualDensity.adaptivePlatformDensity,
            // dense: true,

            tileColor: importFiles.contains(file)
                ? Colors.green.shade50
                : Colors.white,

            leading: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300)
            ),
            width: 50,
            height: 60,
            child: FutureBuilder<ImageProvider?>(
              future: settings.getPdfFirstPageImage(file.path, cache: _pdfThumbCache),
              builder: (context, snapshot) {
                 if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image(image: snapshot.data!, fit: BoxFit.cover),
                  );
                } else {
                  return settings.getFileIcon(fileName);
                }
              },
            ),
          ),

          title: Text(
              fileName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: importFiles.contains(file)
                    ? Colors.blue.shade700
                    : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
            subtitle: settings.getFileDetails(file),
            onTap: () => toggleFileSelection(file),
            trailing: importFiles.contains(file)
                ? const Icon(Icons.check_circle,size: 20, color: Colors.green)
                : null,
          ),
        );
      },
    );
  }

  // ✅ GRID VIEW MODE
  else {
    return GridView.builder(
      padding: EdgeInsets.only(bottom: importFiles.isNotEmpty ? 60 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // ✅ 3 Items per Row
        crossAxisSpacing: 5,
        mainAxisSpacing: 3,
        childAspectRatio: 0.75, // ✅ Adjust height of each card
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        File file = files[index];
        String fileName = file.path.split('/').last;

        return GestureDetector(
          onTap: () => toggleFileSelection(file),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: importFiles.contains(file) ? Colors.blue : Colors.white,
                width: importFiles.contains(file) ? 2 : 0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            color: importFiles.contains(file)
                ? Colors.green.shade50
                : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ File Icon
                  SizedBox(
                    width: 50,
                    height: 60,
                    child: FutureBuilder<ImageProvider?>(
                      future: settings.getPdfFirstPageImage(file.path, cache: _pdfThumbCache),
                      builder: (context, snapshot) {
                       if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image(image: snapshot.data!, fit: BoxFit.cover),
                          );
                        } else {
                          return settings.getFileIcon(fileName);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ File Name with proper text handling
                  Text(
                    fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: importFiles.contains(file)
                          ? Colors.blue.shade700
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // ✅ 2 lines only
                    textAlign: TextAlign.center,  // ✅ Center text
                  ),

                  const SizedBox(height: 4),

                  // // ✅ File Details below name
                  // Expanded(
                  //   flex: 2,
                  //   child: settings.getFileDetailsForGrid(file),
                  // ),
                   Icon(
                      importFiles.contains(file)
                          ? Icons.check_circle
                          :null,
                      color: importFiles.contains(file)
                          ? Colors.green
                          : Colors.white,
                      size: 20)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
