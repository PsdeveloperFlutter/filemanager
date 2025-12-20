import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Inside your State class
final Map<String, ImageProvider> _pdfThumbCache = {};

/// Widget to display files in List or Grid View using GetX (Obx reactive)
Widget buildFilesView({
  required RxList<File> files,            // ✅ Reactive file list
  required RxList<File> importFiles,      // ✅ Reactive selected files
  required RxBool isGridView,             // ✅ Reactive view toggle
  required Function(File) toggleFileSelection,
  required dynamic settings,
}) {
  return Obx(() {
    // ✅ If no files
    if (files.isEmpty) {
      return const Center(child: Text("No Files Found"));
    }

    // ✅ LIST VIEW
    if (!isGridView.value) {
      return ListView.separated(
        separatorBuilder: (context, index) =>
        const Divider(height: 0.2, color: Colors.black12),
        padding: const EdgeInsets.only(top: 0, bottom: 54.8),
        itemCount: files.length,
        itemBuilder: (context, index) {
          File file = files[index];
          String fileName = file.path.split('/').last;

          return Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            child: ListTile(
              tileColor: importFiles.contains(file)
                  ? Colors.green.shade50
                  : Colors.white,
              leading: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                width: 50,
                height: 60,
                child: FutureBuilder<ImageProvider?>(
                  future: settings.getPdfFirstPageImage(
                    file.path,
                    cache: _pdfThumbCache,
                  ),
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
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: importFiles.contains(file)
                      ? Colors.blue.shade700
                      : Colors.black,
                ),
                maxLines: 1,
                softWrap: false,
              ),
              subtitle: settings.getFileDetails(file),
              onTap: () => toggleFileSelection(file),
              trailing: importFiles.contains(file)
                  ? const Icon(Icons.check_circle, size: 20, color: Colors.green)
                  : null,
            ),
          );
        },
      );
    }

    // ✅ GRID VIEW
    else {
      return GridView.builder(
        padding: EdgeInsets.only(bottom: importFiles.isNotEmpty ? 60 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 3,
          childAspectRatio: 0.75,
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
                  color:
                  importFiles.contains(file) ? Colors.blue : Colors.white,
                  width: importFiles.contains(file) ? 2 : 0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              color:
              importFiles.contains(file) ? Colors.green.shade50 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ File thumbnail or icon
                    SizedBox(
                      width: 50,
                      height: 60,
                      child: FutureBuilder<ImageProvider?>(
                        future: settings.getPdfFirstPageImage(
                          file.path,
                          cache: _pdfThumbCache,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child:
                              Image(image: snapshot.data!, fit: BoxFit.cover),
                            );
                          } else {
                            return settings.getFileIcon(fileName);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ File name
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
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // ✅ Check Icon for selected
                    Icon(
                      importFiles.contains(file)
                          ? Icons.check_circle
                          : null,
                      color: importFiles.contains(file)
                          ? Colors.green
                          : Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  });
}
