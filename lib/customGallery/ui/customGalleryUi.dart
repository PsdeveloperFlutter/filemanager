import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'listViewAndGridViewUi.dart';

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
  String selectedFileType = "File Type"; // Currently Selected File Type
  bool _isLoading = true; // Added for loading state
  bool isGridView = false; // Toggle between List and Grid View
  bool _showHiddenFiles = false; // Added to control visibility of hidden files
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
      allFiles = await settings.getFilesFromDirectory(root,
          showHiddenFiles: _showHiddenFiles); // Get File From Directory
      files = List.from(allFiles); //create Copy here
      // Simulate a delay for loading files
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _isLoading = false; // Set loading to false after files are loaded
      });
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
            if (folderPath == "All files") {
              setState(() {
                selectedFolder = "All files";
                files = List.from(allFiles); // Show all files
              });
            } else {
              setState(() {
                selectedFolder = folderPath.split('/').last;
                files = folders[folderPath]!.map((path) => File(path)).toList();
              });
            }
          },
          selectedFolder: selectedFolder,
          onSelectedFolderChanged: (folderPath) {
            setState(() {
              selectedFolder = folderPath;
            });
          },
          context: context,
        );
      },
    );
  }

  //Widget for the Functionality of Import List Section
// Dropdown-style option widget
  Widget buildImportFunctionalityOptions(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        // Background color Selection for the Dropdown
        color: (text == 'All Files' || text == 'Sort By' || text == 'File Type')
            ? Colors.white
            : Colors.blue.shade400, // White background

        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text,
              style: GoogleFonts.poppins(
                color: (text == 'All Files' ||
                        text == 'Sort By' ||
                        text == 'File Type')
                    ? Colors.black
                    : Colors.white,
                fontSize: 12, // Adjusted for better fit
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                color: (text == 'All Files' ||
                        text == 'Sort By' ||
                        text == 'File Type')
                    ? Colors.black
                    : Colors.white,
                size: 20),
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
                // Show Folder Selection Modal
                child: buildImportFunctionalityOptions(
                    selectedFolder ?? "All Files")),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
              onTap: () => settings.showFileTypeBottomSheet(
                context,
                allFiles,
                (filteredFiles, selectedType) {
                  // ✅ Now also receive selectedType
                  setState(() {
                    files = filteredFiles; // update file list
                    selectedFileType = selectedType; // ✅ Set correct text in UI
                  });
                },
              ),
              // Show File Type Selection Modal
              child: buildImportFunctionalityOptions(selectedFileType),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
                onTap: () =>
                    showSortOptionsBottomSheet(context, files, (sortedFiles) {
                      setState(() {
                        files = sortedFiles;
                      });
                    }),
                // Show Sort Options Modal
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
        // Reset all details
        importFiles.clear();
        files = List.from(allFiles); // Reset to all files
        selectedFolder = null; // Reset selected folder
        selectedFileType = "File Type"; // Reset selected file type
      }); // Clear previous selections
      settings.importSelectedFiles(
          context, selectedFiles.map((e) => File(e)).toList(), setState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        iconTheme: const IconThemeData(color: Colors.white),
        // ✅ All icons white
        title: Text(
          "File",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        leading: selectedFolder == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
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
          // Padding(
          //   padding: const EdgeInsets.only(right: 8.0),
          //   child: AnimSearchBar(
          //     width: MediaQuery.of(context).size.width * 0.5, // Responsive width
          //     textController: TextEditingController(),
          //     onSuffixTap: () {
          //       // Clear search or other actions
          //     },
          //     color: Colors.white, // Search bar background color
          //     textFieldColor: Colors.grey[200], onSubmitted: (String ) {  }, // Text field background color
          //   ),
          // ),
          IconButton(
              onPressed: () {
                setState(() {
                  isGridView = !isGridView; // Toggle the boolean value
                });
              },
              icon: Icon(isGridView ? Icons.list : Icons.grid_view)),
          // Popup Menu Buttons for additional options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String result) {
              if (result == 'pickFiles') {
                pickFilesFromSystemGallery();
              }
            },
            offset: const Offset(0, 40),
            // Offset the menu downwards
            color: Colors.white,
            // Set background color to match AppBar

            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0), // Added padding
                value: 'pickFiles',
                child: Padding(
                  // Added Padding widget
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, color: Colors.black),
                      // Icon color white
                      const SizedBox(width: 8),
                      Text(
                        'Open system files',
                        style: GoogleFonts.poppins(
                            color: Colors.black), // Text color white
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1), // Divider with custom height
              PopupMenuItem<String>(
                value: 'toggleHiddenFiles',
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setStatePopup) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          // set here When the USER Click on this so that the background color of the checkbox while be blue
                          fillColor:
                              MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue.shade700;
                            }
                            return Colors.white;
                          }),
                          value: _showHiddenFiles,

                          onChanged: (bool? value) async {
                            // ✅ Make this async instead
                            // First update the local popup UI state
                            setStatePopup(() {
                              _showHiddenFiles = value ?? false;
                            });

                            // Fetch files asynchronously
                            List<File> updatedFiles =
                                await settings.getFilesFromDirectory(
                              Directory('/storage/emulated/0/'),
                              showHiddenFiles: _showHiddenFiles,
                            );

                            // Then call setState synchronously to update main UI
                            setState(() {
                              files = updatedFiles;
                            });
                          },

                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                        ),
                        Text(
                          "Show Hidden Files",
                          style: GoogleFonts.poppins(color: Colors.black),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          buildTopOptionsRow(), // Add the top options row here
          Expanded(
            child: Stack(
              children: [
                // ✅ Main File List
                _isLoading // Check if loading
                    ? const Center(
                        child: CircularProgressIndicator(
                        color: Color(0xFF0A3D62),
                      ))
                    : // Show progress indicator with appbar color
                    files.isEmpty
                        ? Center(child: Text("No files found"))
                        : buildFilesView(
                            //From listViewAndGridViewUi.dart
                            files: files,
                            importFiles: importFiles,
                            isGridView: isGridView,
                            // Change to true for GridView
                            toggleFileSelection: toggleFileSelection,
                            settings: settings,
                          ),

                // ✅ Import List Section at Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                      //Import List Section Function
                      child: importListSection(
                        // ✅ Pass required arguments
                        context,
                        importFiles: importFiles,
                        toggleFileSelection: toggleFileSelection,
                        importSelectedFiles: () => settings.importSelectedFiles(
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      // Adjusted padding
      backgroundColor: const Color(0xFF0A3D62),
      // Button color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: importSelectedFiles,
    child: Text(
      // Changed text to fit medium size
      "Import ",
      style: GoogleFonts.poppins(
        fontSize: 14, // Adjusted font size
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
// Show Folder Selection Modal
Widget buildFolderSelectionSheet({
  required Map<String, List<String>> folders,
  required Function(String folderPath) onFolderSelected,
  required String? selectedFolder,
  required Function(String) onSelectedFolderChanged,
  required BuildContext context,
}) {
  return StatefulBuilder(
    builder: (context, setModalState) {
      return SizedBox(
        height: 400,
        child: Column(
          children: [
            // ✅ App Bar for Modal Bottom Sheet
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, // Dark blue background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                "Select Folder",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // White text
                ),
              ),
            ),

            // ✅ All Files Option
            Card(
              shape: RoundedRectangleBorder(
                // Added this to remove default radius
                borderRadius: BorderRadius.zero,
              ),
              margin: EdgeInsets.zero,
              color: Colors.white,
              child: ListTile(
                //
                leading: Image.asset(
                  'assets/icons/folder (2).webp',
                  width: 34, // Set the width of the image
                  height: 34,
                ),
                trailing: Radio<String>(
                  value: "All files",
                  groupValue: selectedFolder,
                  onChanged: (value) {
                    setModalState(() {
                      selectedFolder = value; // ✅ Update modal state
                    });
                    onSelectedFolderChanged(value!); // Update parent state
                    onFolderSelected("All files");  // Call the callback
                  },
                ),
                title: Text("All files"),
                subtitle: Text("Display all retrieved files"),
                onTap: () {
                  setModalState(() => selectedFolder = "All files");
                  onSelectedFolderChanged("All files");
                  onFolderSelected("All files");
                },
              ),
            ),
            Divider(height: 0.5, color: Colors.grey.shade300),
            // ✅ Folder List with Radio Buttons
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    Divider(height: 0.5, color: Colors.grey.shade300),
                padding: EdgeInsets.zero,
                itemCount: folders.keys.length,
                itemBuilder: (context, index) {
                  String folderPath = folders.keys.elementAt(index);
                  List<String> filesInFolder = folders[folderPath] ?? [];
                  int fileCount = filesInFolder.length;

                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      // Added this to remove default radius
                      borderRadius: BorderRadius.zero,
                    ),
                    child: ListTile(
                      leading: Image.asset(
                        'assets/icons/folder (2).webp',
                        width: 34, // Set the width of the image
                        height: 34,
                      ),
                      trailing: Radio<String>(
                        value: folderPath,
                        groupValue: selectedFolder,
                        onChanged: (value) {
                          setModalState(() => selectedFolder = value);
                          onSelectedFolderChanged(value!);
                          onFolderSelected(folderPath);
                        },
                      ),
                      title: Text(folderPath.split('/').last),
                      subtitle: Text("$fileCount files"),
                      onTap: () {
                        setModalState(() => selectedFolder = folderPath);
                        onSelectedFolderChanged(folderPath);
                        onFolderSelected(folderPath);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showSortOptionsBottomSheet(
    BuildContext context, List<File> files, Function(List<File>) onSorted) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      // ✅ Sort Criteria Options
      final List<String> criteriaOptions = [
        "By Name",
        "By Size",
        "By Date",
      ];
      //Sort By Bottom Sheet Icons List
      final List<String> iconsStrings = [
        'assets/icons/sort-by-alphabet.webp',
        'assets/icons/sort-by-attributes.webp',
        'assets/icons/sort-by-attributes.webp'
      ];

      String? selectedCriteria; // Track selected criteria

      // ✅ Sorting Function
      void sortFiles(String criteria, bool ascending) {
        List<File> sortedFiles = List.from(files); // Copy original list
        switch (criteria) {
          case "By Name":
            sortedFiles.sort((a, b) => a.path
                .split('/')
                .last
                .toLowerCase()
                .compareTo(b.path.split('/').last.toLowerCase()));
            break;
          case "By Size":
            sortedFiles
                .sort((a, b) => a.lengthSync().compareTo(b.lengthSync()));
            break;
          case "By Date":
            sortedFiles.sort(
                (a, b) => a.statSync().changed.compareTo(b.statSync().changed));
            break;
        }

        // ✅ Reverse if descending
        if (!ascending) {
          sortedFiles = sortedFiles.reversed.toList();
        }

        // ✅ Update parent UI
        onSorted(sortedFiles);
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // Reduced height
            child: Column(
              children: [
                // ✅ Title Bar
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Sort Files",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                // ✅ Sort Criteria Options
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) =>
                        const Divider(height: 0.5, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    itemCount: criteriaOptions.length,
                    itemBuilder: (context, index) {
                      String criteria = criteriaOptions[index];
                      return Card(
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<String>(
                          secondary: Image.asset(iconsStrings[index],
                              width: 24, height: 24, color: Colors.blue),
                          title: Text(criteria,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          value: criteria,
                          groupValue: selectedCriteria,
                          onChanged: (value) {
                            setState(() {
                              selectedCriteria = value;
                            });
                          },
                          activeColor: const Color(0xFF0A3D62),
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                      );
                    },
                  ),
                ),

                // ✅ Ascending / Descending Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          sortFiles(selectedCriteria!, true);
                        },
                        icon:
                            const Icon(Icons.arrow_upward, color: Colors.white),
                        label: Text("Ascending",
                            style: GoogleFonts.poppins(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(5), // Rectangle shape
                          ),
                          backgroundColor: const Color(0xFF0A3D62),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          sortFiles(selectedCriteria!, false);
                        },
                        icon: const Icon(Icons.arrow_downward,
                            color: Colors.white),
                        label: Text(
                          "Descending",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(5), // Rectangle shape
                          ),
                          backgroundColor: const Color(0xFF0A3D62),
                        ),
                      ),
                    ],
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
