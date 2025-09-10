import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return ListView.builder(
      padding: EdgeInsets.only(bottom: importFiles.isNotEmpty ? 60 : 0),
      itemCount: files.length,
      itemBuilder: (context, index) {
        File file = files[index];
        String fileName = file.path.split('/').last;

        return Card(
          elevation: 2,
          child: ListTile(
            tileColor: importFiles.contains(file)
                ? Colors.green.shade50
                : Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color:
                      importFiles.contains(file) ? Colors.blue : Colors.white,
                  width: importFiles.contains(file) ? 2 : 0),
              borderRadius: BorderRadius.circular(8),
            ),
            leading: settings.getFileIcon(fileName),
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
              maxLines: 2,
              softWrap: true,
            ),
            subtitle: settings.getFileDetails(file),
            onTap: () => toggleFileSelection(file),
            trailing: importFiles.contains(file)
                ? const Icon(Icons.check_circle, color: Colors.green)
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
        childAspectRatio: 0.65, // ✅ Adjust height of each card
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
                  settings.getFileIcon(fileName),

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

                  // ✅ File Details below name
                  Expanded(
                    flex: 2,
                    child: settings.getFileDetailsForGrid(file),
                  ),
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
