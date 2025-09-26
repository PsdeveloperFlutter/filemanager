import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomGallerySetting {
// Allowed File Extensions
  List<String> allowedExtensions = [
    "pdf",
    "doc",
    "docx",
    "xls",
    "xlsx",
    "ppt",
    "pptx",
    "odt"
  ];

// ✅ Request Storage Permission for Android 10, 11, 12, 13+
  Future<bool> requestStoragePermission() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      // ✅ Android 11+ → Full access
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    } else {
      // ✅ Android 10 & Below
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }



  // ✅ Import files into new folder Logic
  Future<void> importSelectedFiles(BuildContext context, List<File> importFiles,
      StateSetter setState) async {
    if (importFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No files selected for import")),
      );
      return;
    }

    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      Directory baseImportDir = Directory(p.join(appDir.path, "ImportedFiles"));

      // Create base ImportedFiles folder if it doesn't exist
      if (!await baseImportDir.exists()) {
        await baseImportDir.create();
      }

      // Step 2: Create folder with today's date + current time
      String folderName =
      getDateTimeFolderName(); // e.g., "06-09-2025_10-30-15"
      Directory dateTimeFolder =
      Directory(p.join(baseImportDir.path, folderName));

      if (!await dateTimeFolder.exists()) {
        await dateTimeFolder.create();
      }
      // Step 3: Copy files into this new folder
      for (File file in importFiles) {
        String newPath = p.join(dateTimeFolder.path, p.basename(file.path));
        await file.copy(newPath);
      }

      //Step 4: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Files imported successfully!")),
      );

      setState(() {
        importFiles.clear(); // Clear after importing
      });
      Navigator.pop(context, true); // Close the modal after a short delay
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ✅ Helper: Get today's date + time as folder name
  String getDateTimeFolderName() {
    DateTime now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    String year = now.year.toString();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');

    return "$day-$month-$year\_$hour-$minute-$second";
  }

  //Folder Fetch Logic
  Future<List<String>> getImportedFolders() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory baseImportDir = Directory(p.join(appDir.path, "ImportedFiles"));
    if (await baseImportDir.exists()) {
      List<FileSystemEntity> entities = baseImportDir.listSync();
      return entities
          .where(((e) => FileSystemEntity.isDirectorySync(e.path)))
          .map((e) => e.path)
          .toList();
    } else {
      return [];
    }
  }

  // Icon set for Various Extension Files
  Icon getFileIcon(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: Colors.blue, size: 30);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart, color: Colors.green, size: 30);
      case 'ppt':
      case 'pptx':
        return Icon(Icons.slideshow, color: Colors.orange, size: 30);
      case 'odt':
        return Icon(
          Icons.article,
          color: Colors.purple,
          size: 30,
        );
      default:
        return Icon(Icons.insert_drive_file, color: Colors.purple, size: 22);
    }
  }
  // ✅ Add / Remove file from Import List
  void toggleFileSelection(File file,List importFiles, setState, ScrollController _scrollController) {
    setState(() {
      if (importFiles.contains(file)) {
        importFiles.remove(file);
      } else {
        importFiles.add(file);
      }
    });

    // ✅ Scroll to the end after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper function to determine and Identify  storage type
  String getStorageType(String folderPath) {
    if (folderPath.startsWith('/storage/emulated/0')) {
      return 'Internal Storage';
    }
    return 'SD Card';
  }

  // File Subtitle Widget and Info of File'S
  Widget getFileDetails(File file) {
    try {
      final fileStat = file.statSync();

      // ✅ File Size Formatting
      int bytes = fileStat.size;
      String sizeText;
      if (bytes < 1024) {
        sizeText = "$bytes B";
      } else if (bytes < 1024 * 1024) {
        sizeText = "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        sizeText = "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }

      // ✅ Created Date
      String createdDate =
      DateFormat('dd MMM yyyy, hh:mm a').format(fileStat.changed);

      // ✅ Internal vs SD Card Path
      String filePath = file.path;
      String displayPath;
      if (filePath.startsWith('/storage/emulated/0')) {
        String relativePath = filePath.replaceFirst('/storage/emulated/0/', '');
        displayPath = "Internal → $relativePath";
      } else {
        // Try to get a more descriptive path for SD card
        List<String> pathSegments = filePath.split('/');
        // Ensure there are enough segments to avoid errors
        String sdCardPath = pathSegments.length > 3 ? pathSegments.skip(3).join('/') : filePath;
        sdCardPath = sdCardPath.replaceAll('/', ' → ');

        // You might need to adjust this logic based on how SD card paths are structured on various devices
        // This is a common pattern, but not universal.
        displayPath = "SD Card → $sdCardPath"; // Already includes "SD Card →"
      }


      // ✅ Return Column with Two Rows
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Date + Size
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$createdDate , ",
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),

              Text(
                sizeText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
              ),
            ],
          ),

          // Row 2: File Path
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  displayPath,
                  style:
                  GoogleFonts.poppins(fontSize: 9, color: Colors.black87),
                  overflow: TextOverflow.ellipsis, // ✅ Ellipses for long paths
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Text(
        "Error loading file info",
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
      );
    }
  }

// ✅ File Details Widget for GridView
  Widget getFileDetailsForGrid(File file) {
    try {
      final fileStat = file.statSync();

      // ✅ File Size Formatting
      int bytes = fileStat.size;
      String sizeText;
      if (bytes < 1024) {
        sizeText = "$bytes B";
      } else if (bytes < 1024 * 1024) {
        sizeText = "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        sizeText = "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }

      // ✅ Created Date
      String createdDate = DateFormat('dd MMM yyyy').format(fileStat.changed);

      // ✅ Internal vs SD Card Path
      String filePath = file.path;
      String displayPath;
      if (filePath.startsWith('/storage/emulated/0')) {
        String relativePath = filePath.replaceFirst('/storage/emulated/0/', '');
        displayPath = "Internal → $relativePath";
      } else {
        // Try to get a more descriptive path for SD card
        List<String> pathSegments = filePath.split('/');
        // Ensure there are enough segments to avoid errors
        String sdCardPath = pathSegments.length > 3 ? pathSegments.skip(3).join('/') : filePath;
        // You might need to adjust this logic based on how SD card paths are structured on various devices
        // This is a common pattern, but not universal.
        displayPath = "SD Card → ${sdCardPath.replaceAll('/', ' → ')}";
      }

      // ✅ Colors for Icons
      Color dateColor = Colors.deepPurple;
      Color sizeColor = Colors.green;
      Color pathColor = Colors.blueGrey;

      // ✅ Compact UI for Grid View
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Date + Size in one line
          SingleChildScrollView(
           scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.access_time, size: 12, color: dateColor),
                const SizedBox(width: 2),
                Text(
                  createdDate,
                  style: GoogleFonts.poppins(fontSize: 9, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.storage, size: 12, color: sizeColor),
                const SizedBox(width: 2),
                Text(
                  sizeText,
                  style: GoogleFonts.poppins(fontSize: 9, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // ✅ File Path in one line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder, size: 12, color: pathColor),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  displayPath,
                  style:
                  GoogleFonts.poppins(fontSize: 9, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Text(
        "Error loading file info",
        style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
      );
    }
  }


// Yeh variable aapke State class ke andar hoga:
  // String? selectedFileType = "All Files"; // Default // Commented out as it's managed by the parent widget

// Function to show File Type Bottom Sheet
  void showFileTypeBottomSheet(
      BuildContext context,
      List<File> allFiles,
      String? selectedFolderPath, // ✅ selected folder path from parent
      Function(List<File>, String) onFilterApplied,
      String? selectedFileType, // <-- Pass this from parent for state sync
      void Function(String?) onFileTypeChanged, // <-- Callback to update file type globally
      ) {
    List<String> fileTypes = [
      "All Files",
      "PDF",
      "DOC/DOCX",
      "XLS/XLSX",
      "TXT",
      "PPT/PPTX",
      "ODT"
    ];

    List<String> fileTypesIcons = [
      'assets/icons/folder (2).webp',
      'assets/icons/pdf.webp',
      'assets/icons/doc.webp',
      'assets/icons/xls.webp',
      'assets/icons/txt.webp',
      'assets/icons/pptx.webp',
      'assets/icons/odt.webp',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? tempSelectedFileType = selectedFileType;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) { // Explicitly define context type
            void filterFilesByType(String? type) {
              setStateModal(() {
                tempSelectedFileType = type;
              });
              onFileTypeChanged(type); // Update global selection

              // ✅ Filter files based on selected folder first
              List<File> folderFiles;
              if (selectedFolderPath == null || selectedFolderPath == "All files") {
                folderFiles = List.from(allFiles);
              } else {
                folderFiles = allFiles
                    .where((file) => file.path.contains(selectedFolderPath))
                    .toList();
              }

              // ✅ Filter by file type
              List<File> filteredFiles;
              if (type == "All Files" || type == null) {
                filteredFiles = folderFiles;
              } else {
                filteredFiles = folderFiles.where((file) {
                  String name = file.path.toLowerCase();
                  switch (type) {
                    case "PDF":
                      return name.endsWith(".pdf");
                    case "DOC/DOCX":
                      return name.endsWith(".doc") || name.endsWith(".docx");
                    case "XLS/XLSX":
                      return name.endsWith(".xls") || name.endsWith(".xlsx");
                    case "TXT":
                      return name.endsWith(".txt");
                    case "PPT/PPTX":
                      return name.endsWith(".ppt") || name.endsWith(".pptx");
                    case "ODT":
                      return name.endsWith(".odt");
                    default:
                      return false;
                  }
                }).toList();
              }

              // ✅ Display text for UI
              String displayText = (type == "All Files" || type == null) ? "File Type" : type;

              // ✅ Send filtered files back to UI
              onFilterApplied(filteredFiles, displayText);
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: EdgeInsets.all(7),
                          child: Image.asset(
                            'assets/icons/doc1.webp',
                            width: 23,
                            height: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                                "Select File Types",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600
                                )
                            ),
                            const Text(
                                "Select a file",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                )
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade400, height: 0.1),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const Divider(
                        color: Colors.black26,
                        height: 0.1,
                      ),
                      itemCount: fileTypes.length,
                      itemBuilder: (context, index) {
                        String fileType = fileTypes[index];
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          margin: EdgeInsets.zero,
                          child: RadioListTile<String>(
                            secondary: Image.asset(
                                fileTypesIcons[index],
                                width: 23,
                                height: 23
                            ),
                            title: Text(
                              fileType,
                              style: TextStyle(
                                  color: tempSelectedFileType == fileType ? Colors.blue : Colors.black87
                              ),
                            ),
                            value: fileType,
                            groupValue: tempSelectedFileType,
                            onChanged: (value) {
                              filterFilesByType(value);
                            },
                            activeColor: Colors.blue,
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }


// ✅ Fetch Files from System File Manager
  Future<void> pickFilesFromSystemWithAutoFolder(setState, files, context) async {
    List<String> allowedExtensions = [
      "pdf",
      "doc",
      "docx",
      "xls",
      "xlsx",
      "ppt",
      "pptx",
      "odt"
    ];

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      List<String> selectedFiles = result.paths.whereType<String>().toList();

      setState(() {
        files = selectedFiles.map((path) => File(path)).toList();
      });
      try {
        importSelectedFiles(context, files, setState);
        // Future.delayed(Duration(milliseconds: 1000), () {
        //   Navigator.pop(context);
        // });
      } catch (e) {
        debugPrint("\n Error: $e");
      }
    }
  }




  //Sorting Logic
  // ✅ Sorting Function
  void sortFiles(String criteria, bool ascending,
      List<File> files, Function(List<File>) onSorted, BuildContext context,lastSelectedCriteria) {
    List<File> sortedFiles = List.from(files); // Copy original list
    switch (criteria) {
      case "By Name":
        sortedFiles.sort((a, b) =>
            a.path
                .split('/')
                .last
                .toLowerCase()
                .compareTo(b.path
                .split('/')
                .last
                .toLowerCase()));
        break;
      case "By Size":
        sortedFiles.sort((a, b) =>
            a.lengthSync().compareTo(b.lengthSync()));
        break;
      case "By Date":
        sortedFiles.sort((a, b) =>
            a
                .statSync()
                .changed
                .compareTo(b
                .statSync()
                .changed));
        break;
    }

    if (!ascending) {
      sortedFiles = sortedFiles.reversed.toList();
    }

    // ✅ Save last selected criteria
    lastSelectedCriteria = criteria;

    // ✅ Update parent UI and close modal
    onSorted(sortedFiles);
    Navigator.pop(context);
  }

}