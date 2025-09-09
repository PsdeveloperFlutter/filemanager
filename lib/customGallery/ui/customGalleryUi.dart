import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MaterialApp(
    home: CustomGalleryApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class CustomGalleryApp extends StatefulWidget {
  const CustomGalleryApp({super.key});

  @override
  State<CustomGalleryApp> createState() => _CustomGalleryAppState();
}

class _CustomGalleryAppState extends State<CustomGalleryApp> {
  // ✅ Folder List
  List<File> files = []; // All Files
  List<File> allFiles = []; // All Files
  Map<String, List<String>> folders = {}; // Folders with Files
  String? selectedFolder; // Currently Selected Folder

  // ✅ Files user clicked on → shown at the bottom horizontal list
  List<File> importFiles = [];

  // Settings Instance
  final CustomGallerySetting settings = CustomGallerySetting();

  // ✅ ScrollController for horizontal scrolling
  final ScrollController _scrollController = ScrollController();

  // ✅ Add / Remove file from Import List
  void toggleFileSelection(File file) {
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

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  // Load Files and Folders
  Future<void> loadFiles() async {
    bool granted = await settings.requestStoragePermission();
    if (granted) {
      Directory root = Directory('/storage/emulated/0/');
      allFiles =
      await settings.getFilesFromDirectory(root); // Get File From Directory
      files = List.from(allFiles); //create Copy here
      folders =
      await settings.getFoldersWithFiles(root.path); //Get File and folders
      setState(() {});
    }
  }

  void showFolderSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return buildFolderSelectionSheet(
          folders: folders,
          onFolderSelected: (folderPath) {
            setState(() {
              selectedFolder = folderPath
                  .split('/')
                  .last;
              files = folders[folderPath]!.map((path) => File(path)).toList();
            });
            Navigator.pop(context);
          },
          selectedFolder: selectedFolder,
          setState: setState,
          context: context,
        );
      },
    );
  }

  //Widget for the Functionality of Import List Section
// Dropdown-style option widget
  Widget buildImportFunctionalityOptions(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: Offset(0, 1), // subtle shadow for depth
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.black87, // Black text for contrast
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

// Row for All Files, File Type, Sort By
  Widget buildTopOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
                onTap: showFolderSelection,
                child: buildImportFunctionalityOptions(
                    selectedFolder ?? "All Files")),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
                onTap: () =>
                    settings.showFileTypeBottomSheet(
                      context,
                      allFiles, // ← pass the original, unfiltered list
                          (filteredFiles) {
                        setState(() {
                          files = filteredFiles; // update main UI
                        });
                      },
                    ),

                // Show File Type Bottom Sheet
                child: buildImportFunctionalityOptions("File Type")),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
                onTap: () =>showSortOptionsBottomSheet(context,files,(sortedFiles){setState(() {files=sortedFiles;});}),
                child: buildImportFunctionalityOptions("Sort By")),
          ),
        ),
      ],
    );
  }

  // ✅ Fetch Files from System File Manager
  void pickFilesFromSystemGallery() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("File", style: GoogleFonts.poppins()),
        leading: selectedFolder == null
            ? null
            : IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selectedFolder = null;
              files = folders.values
                  .expand((list) => list)
                  .map((path) => File(path))
                  .toList();
            });
          },
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.grid_view)),
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: pickFilesFromSystemGallery,
          )
        ],
      ),
      body: Column(
        children: [
          buildTopOptionsRow(), // Add the top options row here
          Expanded(
            child: Stack(
              children: [
                // ✅ Main File List
                files.isEmpty
                    ? Center(child: Text("No files found"))
                    : ListView.builder(
                  // space for bottom bar
                  padding: EdgeInsets.only(
                      bottom: importFiles.isNotEmpty ? 60 : 0),
                  // Add this line to remove default padding
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    File file = files[index];
                    String fileName = file.path
                        .split('/')
                        .last;
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        tileColor: importFiles.contains(file)
                            ? Colors.green.shade50
                            : Colors.white,
                        style: ListTileStyle.list,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: importFiles.contains(file)
                                  ? Colors.blue
                                  : Colors.white,
                              width: importFiles.contains(file) ? 2 : 0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hoverColor: Colors.blue.shade50,
                        selectedColor: Colors.blue.shade100,
                        leading: settings.getFileIcon(fileName),

                        // ✅ Wrap file name in Row -> Expanded -> Text
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fileName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: importFiles.contains(file)
                                      ? Colors
                                      .blue.shade700 // Selected color
                                      : Colors.black, // Default color
                                ),
                                overflow: TextOverflow.ellipsis,
                                // ✅ Ellipsis applied properly
                                maxLines: 2,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),

                        subtitle: settings.getFileDetails(file),
                        onTap: () => toggleFileSelection(file),
                        trailing: importFiles.contains(file)
                            ? Icon(Icons.check_circle,
                            color: Colors.green)
                            : null,
                      ),
                    );
                  },
                ),

                // ✅ Import List Section at Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top:
                          BorderSide(color: Colors.blue.shade300, width: 1),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      //Import List Section Function
                      child: importListSection(
                        // ✅ Pass required arguments
                        context,
                        importFiles: importFiles,
                        toggleFileSelection: toggleFileSelection,
                        importSelectedFiles: () =>
                            settings.importSelectedFiles(
                                context, importFiles, setState),
                        scrollController: _scrollController,
                        settings: settings,
                      )),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//Import List UI
Widget importListSection(BuildContext context,
    {required List<File> importFiles,
      required Function(File file) toggleFileSelection,
      required VoidCallback importSelectedFiles,
      required ScrollController scrollController,
      required CustomGallerySetting settings}) {
  return
    // ✅ Import Button on Right Side
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        backgroundColor: Colors.blue.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: importSelectedFiles,
      child: Text(
        "Import ",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

  // return Row(
  //   children: [
  //     // // ✅ Horizontal File List
  //     // Expanded(
  //     //   child: SizedBox(
  //     //     height: 100,
  //     //     child: ListView.builder(
  //     //       controller: scrollController, // ✅ Attach controller here
  //     //       scrollDirection: Axis.horizontal,
  //     //       itemCount: importFiles.length,
  //     //       itemBuilder: (context, index) {
  //     //         File file = importFiles[index];
  //     //         String fileName = p.basename(file.path);
  //     //
  //     //         return Container(
  //     //           width: 100,
  //     //           margin: EdgeInsets.only(right: 8),
  //     //           padding: EdgeInsets.all(6),
  //     //           decoration: BoxDecoration(
  //     //             color: Colors.white,
  //     //             borderRadius: BorderRadius.circular(10),
  //     //             border: Border.all(color: Colors.green, width: 1),
  //     //           ),
  //     //           child: SingleChildScrollView(
  //     //             child: Column(
  //     //               mainAxisAlignment: MainAxisAlignment.center,
  //     //               children: [
  //     //                 settings.getFileIcon(fileName),
  //     //                 SizedBox(height: 4),
  //     //                 Text(
  //     //                   fileName,
  //     //                   style: TextStyle(fontSize: 12),
  //     //                   overflow: TextOverflow.ellipsis,
  //     //                 ),
  //     //                 IconButton(
  //     //                   icon: Icon(Icons.minimize, size: 28, color: Colors.red),
  //     //                   onPressed: () => toggleFileSelection(file),
  //     //                 ),
  //     //               ],
  //     //             ),
  //     //           ),
  //     //         );
  //     //       },
  //     //     ),
  //     //   ),
  //     // ),
  //
  //   ],
  // );
}

// Show Folder Selection Modal
Widget buildFolderSelectionSheet({
  required Map<String, List<String>> folders,
  required Function(String folderPath) onFolderSelected,
  String? selectedFolder,
  required StateSetter setState,
  required BuildContext context,
}) {
  return SizedBox(
    height: 400,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Icon(Icons.folder, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                "All System Folders",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: folders.keys.length,
            itemBuilder: (context, index) {
              String folderPath = folders.keys.elementAt(index);
              List<String> filesInFolder = folders[folderPath] ?? [];
              int fileCount = filesInFolder.length;

              return Card(
                elevation: 1,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.folder, color: Colors.orange),
                  trailing: Radio<String>(
                    value: folderPath,
                    groupValue: selectedFolder,
                    onChanged: (value) {
                      setState(() {
                        selectedFolder = value;
                      });
                      onFolderSelected(folderPath);
                    },
                  ),
                  title: Text(folderPath
                      .split('/')
                      .last),
                  subtitle: Text("$fileCount files"),
                  onTap: () {
                    setState(() {
                      selectedFolder = folderPath;
                    });
                    onFolderSelected(folderPath);
                  },
                ),
              );
            },
          ),
        )
      ],
    ),
  );
}

void showSortOptionsBottomSheet(BuildContext context,List<File>files,Function(List<File>)onSorted) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // List of sort options
        final List<String> sortOptions = [
          "A - Z",
          "Z - A",
          "Size (Ascending)",
          "Size (Descending)",
          "Date Created (Newest First)",
          "Date Created (Oldest First)",
          "Date Modified (Newest First)",
          "Date Modified (Oldest First)",
        ];

        String? selectedSortOption; // Track selected option
        // ✅ Sorting Function
        void sortFiles(String option){
          List<File> sortedFiles=List.from(files); // Create a copy to sort
          switch(option){
            case "A - Z":
              sortedFiles.sort((a,b)=>a.path.split('/').last.toLowerCase().compareTo(b.path.split('/').last.toLowerCase()));
              break;
            case "Z - A":
              sortedFiles.sort((a,b)=>b.path.split('/').last.toLowerCase().compareTo(a.path.split('/').last.toLowerCase()));
              break;
            case "Size (Ascending)":
              sortedFiles.sort((a,b)=>a.lengthSync().compareTo(b.lengthSync()));
              break;
            case "Size (Descending)":
              sortedFiles.sort((a,b)=>b.lengthSync().compareTo(a.lengthSync()));
              break;
            case "Date Created (Newest First)":
              sortedFiles.sort((a,b)=>b.statSync().changed.compareTo(a.statSync().changed));
              break;
            case "Date Created (Oldest First)":
              sortedFiles.sort((a,b)=>a.statSync().changed.compareTo(b.statSync().changed));
              break;
            case "Date Modified (Newest First)":
              sortedFiles.sort((a,b)=>b.statSync().modified.compareTo(a.statSync().modified));
              break;
            case "Date Modified (Oldest First)":
              sortedFiles.sort((a,b)=>a.statSync().modified.compareTo(b.statSync().modified));
              break;
          }
          // ✅ Update file list in parent widget
          onSorted(sortedFiles);
        }


        return StatefulBuilder(builder: (context, setState) {
          return SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.5, //HalfScreen
              child: Column(
                children: [
                  // ✅ Title Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Sort Files By",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // ✅ Sorting Options with Radio Buttons
                  Expanded(child:
                    ListView.builder(
                      itemCount: sortOptions.length,
                      itemBuilder: (context, index) {
                        String option = sortOptions[index];
                        return Card(
                          elevation: 2,
                          child: RadioListTile<String>(
                            title: Text(option, style: GoogleFonts.poppins()),
                            value: option,
                            groupValue: selectedSortOption,
                            onChanged: (value) {
                              setState(() {
                                selectedSortOption = value;// ✅ Update selected option
                              });
                              if (value != null) {
                                sortFiles(value); // ✅ Now actually sorts
                              }
                            },
                            activeColor: Colors.blue,
                            selected: selectedSortOption == option,
                            controlAffinity: ListTileControlAffinity.trailing,

                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
          );
        });
      });
}
