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
  Map<String, List<File>> folders = {}; // Folders with Files
  String? selectedFolder =
      "All files"; // Currently Selected Folder, default to "All files"
  String selectedFileType = "File Type"; // Currently Selected File Type
  bool _isLoading = true; // Added for loading state
  bool isGridView = false; // Toggle between List and Grid View
  bool _showHiddenFiles = false; // Added to control visibility of hidden files
  // ✅ Files user clicked on → shown at the bottom horizontal list
  List<File> importFiles = [];
  bool _isSearching = false;
  TextEditingController searchController = TextEditingController();

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
      selectedFolder = "All files"; // Ensure "All files" is selected by default
      // Simulate a delay for loading files
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _isLoading = false; // Set loading to false after files are loaded
      });
      // Suppose root.path is your base path
      Map<String, List<String>> foldersString =
          await settings.getFoldersWithFiles(root.path);

// Convert to Map<String, List<File>>
      folders = foldersString.map((folderPath, filePaths) {
        List<File> fileObjects = filePaths.map((path) => File(path)).toList();
        return MapEntry(folderPath, fileObjects);
      });
//Get File and folders
      setState(() {});
    }
  }

  String? lastSelectedFolder =
      "All files"; // Track last selected folder globally

  void showFolderSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // ✅ Initially set to last selected folder
        String? selectedFolder = lastSelectedFolder;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return buildFolderSelectionSheet(
              folders: folders,
              // Pass the original folders map
              selectedFolder: selectedFolder,
              onFolderSelected: (folderPath, folderFiles) {
                setStateModal(() {
                  allFiles =
                      folderFiles; // Update allFiles to current folder files
                  selectedFolder = folderPath;
                });

                setState(() {
                  lastSelectedFolder = folderPath; // <-- Final value set
                  files = folderPath == "All files"
                      ? List.from(allFiles)
                      : List<File>.from(
                          folders[folderPath]!); // Use the files directly
                });
              },
              onSelectedFolderChanged: (folderPath) {
                setStateModal(() {
                  selectedFolder = folderPath;
                });
              },
              context: context,
            );
          },
        );
      },
    );
  }

  //Widget for the Functionality of Import List Section
// Dropdown-style option widget
  Widget buildImportFunctionalityOptions(String text) {
    bool isWhiteBg = (text == 'All Files' ||
        text == "All files" ||
        text == 'Sort By' ||
        text == 'File Type');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isWhiteBg ? Colors.white : Colors.blue.shade400,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        // ✅ Proper vertical alignment
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: isWhiteBg ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2), // ✅ Small gap between text and arrow
          Center(
            child: Icon(
              Icons.arrow_drop_down,
              color: isWhiteBg ? Colors.black : Colors.white,
              size: 18, // ✅ Slightly smaller for better alignment
            ),
          ),
        ],
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
                    lastSelectedFolder == "All files"
                        ? "All Files"
                        : lastSelectedFolder?.split('/').last ?? "All Files")),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
              onTap: () {
                if (selectedFolder != null && selectedFolder != "All files") {
                  // ✅ Get files of the selected folder
                  List<File> folderFiles = folders[selectedFolder] ?? [];

                  settings.showFileTypeBottomSheet(
                    context,
                    folderFiles, // ✅ Pass only selected folder files
                    selectedFolder,
                    (filteredFiles, selectedType) {
                      setState(() {
                        files = filteredFiles; // update file list
                        selectedFileType = selectedType; // update UI
                      });
                    },
                  );
                } else {
                  // All files selected
                  settings.showFileTypeBottomSheet(
                    context,
                    allFiles,
                    selectedFolder,
                    (filteredFiles, selectedType) {
                      setState(() {
                        files = filteredFiles; // update file list
                        selectedFileType = selectedType; // update UI
                      });
                    },
                  );
                }
              },

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
                    //Show Sort Options Modal Bottom Sheet
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

  String? lastSelectedCriteria; // <-- Store this globally in your widget

  void showSortOptionsBottomSheet(
    BuildContext context,
    List<File> files,
    Function(List<File>) onSorted,
  ) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        // ✅ Sort Criteria Options
        final List<String> criteriaOptions = [
          "By Date",
          "By Name",
          "By Size",
        ];

        // ✅ Sort Icons
        final List<String> iconsStrings = [
          'assets/icons/calendar.webp',
          'assets/icons/sort-by-alphabet.webp',
          'assets/icons/expand.webp',
        ];

        // ✅ Use last selected or default
        String? selectedCriteria = lastSelectedCriteria ?? "By Date";

        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                children: [
                  // ✅ Title Section
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.all(7),
                          child: Image.asset(
                            'assets/icons/sort-by-attributes.webp',
                            width: 22,
                            height: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sort Files",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "Select sort by",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0.1, color: Colors.grey.shade300),

                  // ✅ Radio List for Sorting Options
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          const Divider(height: 0.1, color: Colors.grey),
                      itemCount: criteriaOptions.length,
                      itemBuilder: (context, index) {
                        String criteria = criteriaOptions[index];
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: RadioListTile<String>(
                            secondary: Image.asset(
                              iconsStrings[index],
                              width: 22,
                              height: 22,
                              color: selectedCriteria == criteria
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                            title: Text(
                              criteria,
                              style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w500,
                                color: selectedCriteria == criteria
                                    ? Colors.blue
                                    : Colors
                                        .black, // Change text color when selected
                              ),
                            ),
                            value: criteria,
                            groupValue: selectedCriteria,
                            onChanged: (value) {
                              setState(() {
                                selectedCriteria = value;
                                lastSelectedCriteria =
                                    value; // ✅ Save last selection
                              });
                            },
                            activeColor: Colors.blue,
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
                      children: [
                        ElevatedButton.icon(
                          onPressed: selectedCriteria == null
                              ? null
                              : () => settings.sortFiles(
                                    selectedCriteria!,
                                    true,
                                    files,
                                    onSorted,
                                    context,
                                    lastSelectedCriteria,
                                  ),
                          icon: const Icon(Icons.arrow_upward,
                              color: Colors.white),
                          label: Text(
                              lastSelectedCriteria == "By Name"
                                  ? "A to Z"
                                  : lastSelectedCriteria == "By Date"
                                      ? "Oldest"
                                      : lastSelectedCriteria == "By Size"
                                          ? "Smallest"
                                          : "Oldest",
                              style: GoogleFonts.poppins(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            backgroundColor: const Color(0xFF0A3D62),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: selectedCriteria == null
                              ? null
                              : () => settings.sortFiles(
                                    selectedCriteria!,
                                    false,
                                    files,
                                    onSorted,
                                    context,
                                    lastSelectedCriteria,
                                  ),
                          icon: const Icon(Icons.arrow_downward,
                              color: Colors.white),
                          label: Text(
                              lastSelectedCriteria == "By Name"
                                  ? "Z to A"
                                  : lastSelectedCriteria == "By Date"
                                      ? "Newest"
                                      : lastSelectedCriteria == "By Size"
                                          ? "Largest"
                                          : "Newest",
                              style: GoogleFonts.poppins(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            backgroundColor: const Color(0xFF0A3D62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        iconTheme: const IconThemeData(color: Colors.white),
        title: !_isSearching
            ? Text(
                "File",
                style: GoogleFonts.poppins(color: Colors.white),
              )
            : TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search files...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  setState(() {
                    if (query.isEmpty) {
                      files = List.from(allFiles);
                    } else {
                      files = allFiles
                          .where((file) => file.path
                              .split('/')
                              .last
                              .toLowerCase()
                              .contains(query.trim().toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    searchController.clear();
                    // TODO: Reset file list if needed
                    files = List.from(allFiles);
                  });
                },
              )
            : (selectedFolder == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        selectedFolder = null;
                        files = List.from(allFiles); // Reset to all files
                      });
                    },
                  )),
        actions: _isSearching
            ? [] // Hide all icons when searching
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                  icon: Icon(isGridView ? Icons.list : Icons.grid_view,
                      color: Colors.white),
                ),
                PopupMenuButton<String>(
                  menuPadding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String result) {
                    if (result == 'pickFiles') {
                      pickFilesFromSystemGallery();
                    }
                  },
                  offset: const Offset(0, 40),
                  color: Colors.white,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    // ✅ Open system files item
                    PopupMenuItem<String>(
                      value: 'pickFiles',
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6), // Same padding for both
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder, color: Colors.black),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Open system files',
                                style: GoogleFonts.poppins(color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Show hidden files item with checkbox
                    PopupMenuItem<String>(
                      value: 'toggleHiddenFiles',
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      // Same padding
                      child: StatefulBuilder(
                        builder: (context, setStatePopup) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                // ✅ Prevent extra height
                                visualDensity: VisualDensity.compact,
                                // ✅ Reduce default padding
                                fillColor:
                                    MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.blue.shade700;
                                  }
                                  return Colors.white;
                                }),
                                value: _showHiddenFiles,
                                onChanged: (bool? value) async {
                                  setStatePopup(() {
                                    _showHiddenFiles = value ?? false;
                                  });
                                  List<File> updatedFiles =
                                      await settings.getFilesFromDirectory(
                                    Directory('/storage/emulated/0/'),
                                    showHiddenFiles: _showHiddenFiles,
                                  );
                                  setState(() {
                                    files = updatedFiles;
                                  });
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Show Hidden Files",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                )
              ],
      ),
      body: Column(
        children: [
          buildTopOptionsRow(), // Add the top options row here
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ✅ Main File List with Padding for the Bottom Import List
                _isLoading // Check if loading
                    ? const Center(
                        child: CircularProgressIndicator(
                        color: Color(0xFF0A3D62),
                      ))
                    : // Show progress indicator with appbar color
                    files.isEmpty
                        ? Center(
                            child: Text(
                                "No files found in ${lastSelectedFolder?.split('/').last}"))
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
                      color: Colors.white,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      // Adjusted padding
      backgroundColor: importFiles.isEmpty
          ? Colors.grey.withOpacity(0.2)
          : const Color(0xFF0A3D62),

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
        color: importFiles.isEmpty ? Colors.white : Colors.white,
      ),
    ),
  );
}

// Show Folder Selection Modal
// Show Folder Selection Modal
Widget buildFolderSelectionSheet({
  required Map<String, List<File>>
      folders, // Changed List<String> -> List<File>
  required Function(String folderPath, List<File> folderFiles)
      onFolderSelected, // return files for selected folder
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
            // ✅ Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.folder, size: 24, color: Colors.black),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "All System Folders",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "Select a folder",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 0.1, color: Colors.grey.shade300),
            // ✅ Folder List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // All Files Option
                  Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    child: RadioListTile<String>(
                      visualDensity: const VisualDensity(vertical: -3),
                      value: "All files",
                      groupValue: selectedFolder ?? "All files",
                      onChanged: (value) {
                        setModalState(() => selectedFolder = value);
                        onSelectedFolderChanged(value!);
                        // Send all files for "All files"
                        onFolderSelected("All files",
                            folders.values.expand((e) => e).toList());
                      },
                      activeColor: Colors.blue,
                      title: Text(
                        "All files",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: selectedFolder == "All files"
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "${folders.values.expand((e) => e).length} files",
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedFolder == "All files"
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                      secondary: Icon(
                        Icons.folder,
                        size: 24,
                        color: selectedFolder == "All files"
                            ? Colors.blue
                            : Colors.black,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ),
                  Divider(height: 0.2, color: Colors.grey.shade300),

                  // Folder-specific files
                  ...folders.keys.map((folderPath) {
                    List<File> filesInFolder = folders[folderPath] ?? [];
                    return Column(
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          color: Colors.white,
                          child: RadioListTile<String>(
                            visualDensity: const VisualDensity(vertical: -3),
                            value: folderPath,
                            groupValue: selectedFolder,
                            onChanged: (value) {
                              setModalState(() => selectedFolder = value);
                              onSelectedFolderChanged(value!);
                              onFolderSelected(folderPath,
                                  filesInFolder); // ✅ Send only folder files
                            },
                            activeColor: Colors.blue,
                            title: Text(
                              folderPath.split('/').last,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: selectedFolder == folderPath
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              "${filesInFolder.length} files",
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedFolder == folderPath
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                            secondary: Icon(
                              Icons.folder,
                              size: 24,
                              color: selectedFolder == folderPath
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        ),
                        Divider(height: 0.1, color: Colors.grey.shade300),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
