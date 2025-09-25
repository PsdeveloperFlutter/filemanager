import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:filemanager/customGallery/ui/customGalleryUiHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'listViewAndGridViewUi.dart';

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
  bool showSdCardFiles = false;
  bool hasSdCard = false; // SD Card present है या नहीं
  String? sdCardPath;
  TextEditingController searchController = TextEditingController();

  // Settings Instance
  final CustomGallerySetting settings = CustomGallerySetting();

  // ✅ ScrollController for horizontal scrolling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadFiles();
    settings.checkSdCard(sdCardPath, hasSdCard, setState);
  }

  /// Fetches files from external storage directories.
  /// It requests storage permission, then iterates through available storage paths.
  /// For each path, it retrieves files and folders, updating the `allFiles` and `folders` state variables.

  // Load Files and Folders
  Future<void> loadFiles() async {
    bool granted = await settings.requestStoragePermission();
    if (granted) {
      List<String>? storagePaths = await ExternalPath.getExternalStorageDirectories();
      allFiles = [];
      folders = {};

      for (int i = 0; i < storagePaths!.length; i++) {
        String path = storagePaths[i];

        // Internal हमेशा 0th index, SD Card 1st index
        if (i == 1 && !showSdCardFiles) {
          continue; // SD Card अनचेक है तो Skip करो
        }

        Directory root = Directory(path);
        List<File> storageFiles = await settings.getFilesFromDirectory(
          root,
          showHiddenFiles: _showHiddenFiles,
        );
        allFiles.addAll(storageFiles);

        Map<String, List<String>> foldersString =
        await settings.getFoldersWithFiles(root.path);
        folders.addAll(foldersString.map((folderPath, filePaths) {
          List<File> fileObject = filePaths.map((e) => File(e)).toList();
          return MapEntry(folderPath, fileObject);
        }));
      }

      files = List.from(allFiles);
      selectedFolder = "All files";
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = false;
      });
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
        String? tempSelectedFolder = lastSelectedFolder;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return buildFolderSelectionSheet(
              folders: folders,
              selectedFolder: tempSelectedFolder,
              selectedFileType: selectedFileType,
              allFiles: allFiles,
              context: context,
              onFolderSelected: (folderPath, _) {
                // First update modal radio UI
                setStateModal(() {
                  tempSelectedFolder = folderPath;
                });
                // Then update parent state and filter files
                setState(() {
                  lastSelectedFolder = folderPath;
                  selectedFolder = folderPath;
                  files = settings.getFilteredFiles(
                    allFiles: allFiles,
                    folderPath: folderPath,
                    fileType: selectedFileType,
                  );
                });
              },
            );
          },
        );
      },
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
                    : lastSelectedFolder
                    ?.split('/')
                    .last ?? "All Files")),
      ),
    ),
    Expanded(
    flex: 2,
    child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: GestureDetector(
    onTap: () {
    // ✅ अगर selectedFileType null या empty है, तो default "All Files" set करो
    if (selectedFileType == null || selectedFileType!.isEmpty || selectedFileType == "File Type") {
    selectedFileType = "All Files";
    }

    if (selectedFolder != null && selectedFolder != "All files") {
    // ✅ Get files of the selected folder
    List<File> folderFiles = folders[selectedFolder] ?? [];
    settings.showFileTypeBottomSheet(
    context,
    allFiles, // हमेशा allFiles का use करो
    selectedFolder,
    (filteredFiles, selectedType) {
    setState(() {
    files = settings.getFilteredFiles(
    allFiles: allFiles,
    folderPath: selectedFolder,
    fileType: selectedType,
    );
    selectedFileType = selectedType == null || selectedType.isEmpty
    ? "All Files"
        : selectedType; // UI update
    });
    },
    selectedFileType, // ✅ अब हमेशा valid value pass होगी
    (newType) {
    setState(() {
    selectedFileType = newType ?? "All Files";
    files = settings.getFilteredFiles(
    allFiles: allFiles,
    folderPath: selectedFolder,
    fileType: selectedFileType,
    );
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
    files = filteredFiles;
    selectedFileType = selectedType ?? "All Files"; // ✅ Always All Files as default
    });
    },
    selectedFileType, // ✅ अब हमेशा valid value pass होगी
    (newType) {
    setState(() {
    selectedFileType = newType ?? "All Files";
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
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
            Navigator.pop(context);
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
            padding: EdgeInsets.zero, // ✅ Remove extra space on PopupMenuButton
            borderRadius: BorderRadius.circular(0),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String result) {
              if (result == 'pickFiles') {
                settings.pickFilesFromSystemWithAutoFolder(setState, files, context);
              }
            },
            offset: const Offset(0, 40),
            color: Colors.white,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // ✅ Open system files item
              PopupMenuItem<String>(
                height: 30,
                value: 'pickFiles',
                padding: EdgeInsets.zero, // Remove Flutter's default padding
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5), // ✅ Exactly 5px on both sides
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder, color: Colors.black),
                      const SizedBox(width: 7),
                      Text(
                        'Open System Files',
                        style: GoogleFonts.poppins(color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Show SD card files option
              PopupMenuItem<String>(
                height: 30,
                value: 'toggleSdCardFiles',
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: StatefulBuilder(
                    builder: (context, setStatePopup) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            fillColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.blue.shade700;
                              }
                              return Colors.white;
                            }),
                            value: showSdCardFiles,
                            onChanged: (bool? value) async {
                              setStatePopup(() {
                                showSdCardFiles = value ?? false;
                              });
                              setState(() {
                                _isLoading = true;
                                lastSelectedFolder = "All files";
                              });
                              await loadFiles();
                            },
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Show SD Card Files",
                            style: GoogleFonts.poppins(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ✅ Show hidden files option
              PopupMenuItem<String>(
                height: 30,
                value: 'toggleHiddenFiles',
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: StatefulBuilder(
                    builder: (context, setStatePopup) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            fillColor: MaterialStateProperty.resolveWith((states) {
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
                          const SizedBox(width: 5),
                          Text(
                            "Show Hidden Files",
                            style: GoogleFonts.poppins(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
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
                        "No files found in ${lastSelectedFolder
                            ?.split('/')
                            .last}"))
                    : buildFilesView(
                  //From listViewAndGridViewUi.dart
                  files: files,
                  importFiles: importFiles,
                  isGridView: isGridView,
                  // Change to true for GridView
                  toggleFileSelection: (File file) =>
                      settings.toggleFileSelection(file, importFiles,
                          setState, _scrollController),
                  settings: settings,
                ),
                // ✅ Import List Bottom
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
                        toggleFileSelection: (File file) =>
                            settings.toggleFileSelection(
                                file, importFiles, setState, _scrollController),
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

// Show Folder Selection Modal
// Show Folder Selection Modal
// FOLDER SELECTION BOTTOM SHEET WIDGET

Widget buildFolderSelectionSheet({
  required Map<String, List<File>> folders,
  required String? selectedFolder,
  required String? selectedFileType,
  required List<File> allFiles,
  required BuildContext context,
  required void Function(String folderPath, List<File> filteredFiles)
  onFolderSelected,
}) {
  List<String> folderNames = folders.keys.toList();
  folderNames.insert(0, "All files"); // Default option on top

  return SizedBox(
    height: MediaQuery
        .of(context)
        .size
        .height * 0.5,
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
                child: Icon(Icons.folder, size: 23, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Select Folder",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Text("Show files from folder",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ))
                ],
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.shade400, height: 0.1),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) =>
            const Divider(
              color: Colors.black26,
              height: 0.1,
            ),
            itemCount: folderNames.length,
            itemBuilder: (context, index) {
              String folderName = folderNames[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                margin: EdgeInsets.zero,
                child: SizedBox(
                  height: 65,
                  child: RadioListTile<String>(
                    secondary: Icon(Icons.folder,
                        color: selectedFolder == folderName
                            ? Colors.blue
                            : Colors.black,
                        size: 23),
                    title: Text(
                      folderName
                          .split('/')
                          .last,
                      style: TextStyle(
                          color: selectedFolder == folderName
                              ? Colors.blue
                              : Colors.black87),
                    ),
                    subtitle: folderName == "All files"
                        ? Text(
                      "${allFiles.length} files",
                      style: TextStyle(
                        color: selectedFolder == folderName
                            ? Colors.blue
                            : Colors.black87,
                      ),
                    )
                        : Text(
                      "${folders[folderName]?.length ??
                          0} files - ${CustomGallerySetting().getStorageType(
                          folderName)}",
                      style: TextStyle(
                        color: selectedFolder == folderName
                            ? Colors.blue
                            : Colors.black87,
                      ),
                    ),
                    value: folderName,
                    groupValue: selectedFolder,
                    onChanged: (value) {
                      if (value != null) {
                        // Filter files based on current file type and selected folder
                        // Use settings.getFilteredFiles
                        // final filteredFiles = settings.getFilteredFiles(
                        // Use CustomGallerySetting.getFilteredFiles if it's static, or create an instance
                        // For example, if it's static:
                        final filteredFiles =
                        CustomGallerySetting().getFilteredFiles(
                          allFiles: allFiles,
                          folderPath: value,
                          fileType: selectedFileType,
                        );
                        onFolderSelected(value, filteredFiles);
                      }
                    },
                    activeColor: Colors.blue,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ),
              );
            },
          ),
        )
      ],
    ),
  );
}
