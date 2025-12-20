import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:filemanager/customGallery/settings/customGallerySetting.dart';
import 'package:filemanager/customGallery/settings/fileFetchSetting.dart';
import 'package:filemanager/customGallery/ui/customGalleryUiHelper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'listViewAndGridViewUi.dart';

class CustomGalleryApp extends StatefulWidget {
  const CustomGalleryApp({super.key});

  @override
  State<CustomGalleryApp> createState() => _CustomGalleryAppState();
}

class _CustomGalleryAppState extends State<CustomGalleryApp> {
  // ✅ Folder List
  RxList<File> files = <File>[].obs; // Currently visible files
  RxList<File> allFiles = <File>[].obs; // Master all files
  final RxMap<String, List<File>> folders = <String, List<File>>{}.obs;
  final RxnString selectedFolder = RxnString("All files");
  final RxString selectedFileType = "File Type".obs;
  RxBool _isLoading = true.obs;
  RxBool isGridView = false.obs;
  RxBool _showHiddenFiles = false.obs;

  // Make importFiles reactive so UI updates automatically
  RxList<File> importFiles = <File>[].obs;

  RxBool _isSearching = false.obs;
  RxBool showSdCardFiles = false.obs;
  RxBool hasSdCard = false.obs;
  RxnString sdCardPath = RxnString(null);
  TextEditingController searchController = TextEditingController();

  // Settings Instance
  final CustomGallerySetting settings = CustomGallerySetting();
  final FileFetchSettings fileSettings = FileFetchSettings();

  // ScrollController for horizontal import list
  final ScrollController _scrollController = ScrollController();

  // For tracking last selected folder path and display name (non-reactive display name kept reactive via obs where needed)
  String? lastSelectedFolderPath;
  RxString selectedFolderDisplayName = "All files".obs;

  @override
  void initState() {
    super.initState();

    // Load files initially
    loadFiles();

    // Replace passing setState with a no-op and update Rx values in callback
    // (Assuming checkSdCard signature accepts a function and callback)
    // Check SD Card reactively
    fileSettings.checkSdCard(sdCardPath, hasSdCard);
  }

  /// Load files from available external paths
  Future<void> loadFiles() async {
    bool granted = await settings.requestStoragePermission();
    if (!granted || !mounted) return;

    List<String>? storagePaths =
        await ExternalPath.getExternalStorageDirectories();
    allFiles.clear();
    folders.clear();

    if (storagePaths == null) {
      _isLoading.value = false;
      return;
    }

    for (int i = 0; i < storagePaths.length; i++) {
      String path = storagePaths[i];

      // Skip SD card if user has unchecked it
      if (i == 1 && !showSdCardFiles.value) {
        continue;
      }

      Directory root = Directory(path);
      List<File> storageFiles = await fileSettings.getFilesFromDirectory(
        root,
        showHiddenFiles: _showHiddenFiles.value,
      );

      allFiles.addAll(storageFiles);

      Map<String, List<String>> foldersString =
          await fileSettings.getFoldersWithFiles(root.path);
      folders.addAll(foldersString.map((folderPath, filePaths) {
        List<File> fileObject = filePaths.map((e) => File(e)).toList();
        return MapEntry(folderPath, fileObject);
      }));
    }

    // Default to all files
    files.assignAll(allFiles);
    selectedFolder.value = "All files";
    lastSelectedFolderPath = null;
    selectedFolderDisplayName.value = "All files";
    // Small delay to allow any UI transitions like loader; keep if desired
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading.value = false;
  }

  /// Convert folder path to friendly display name
  String _getDisplayName(String folderPath) {
    String lastSegment = folderPath.split('/').last;

    if (lastSegment == '0') return "Internal Storage";
    if (RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$').hasMatch(lastSegment)) {
      return "Disk";
    }
    return lastSegment;
  }

  /// Show folder selection bottom sheet. We keep StatefulBuilder inside the sheet for modal-local interactions.
  void showFolderSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Temporary selection inside modal
        RxnString tempSelectedFolderPath = RxnString(lastSelectedFolderPath);

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return buildFolderSelectionSheet(
              folders: folders,
              // RxMap is compatible; buildSheet reads its keys
              selectedFolder:
                  tempSelectedFolderPath.value ?? selectedFolder.value,
              selectedFileType: selectedFileType.value,
              allFiles: allFiles.toList(),
              context: context,
              onFolderSelected: (folderPath, filteredFiles) {
                // Update temporary modal selection UI
                setStateModal(() {
                  tempSelectedFolderPath.value = folderPath;
                });

                // Update parent reactive state (no setState)
                lastSelectedFolderPath =
                    folderPath == "All files" ? null : folderPath;
                selectedFolderDisplayName.value = folderPath == "All files"
                    ? "All files"
                    : _getDisplayName(folderPath ?? 'All files');
                selectedFolder.value = folderPath;

                // Update visible files according to selected folder and currently selectedFileType
                files.assignAll(fileSettings.getFilteredFiles(
                  allFiles: allFiles,
                  folderPath: folderPath ?? "All files",
                  fileType: selectedFileType.value,
                ));
              },
            );
          },
        );
      },
    );
  }

  // Top options row: wrapped in Obx implicitly by top-level Obx in build
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
                child: Obx(() => buildImportFunctionalityOptions(
                    selectedFolderDisplayName.value))),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
              onTap: () {
                // Ensure selectedFileType has a valid fallback
                if (selectedFileType.value.isEmpty ||
                    selectedFileType.value == "File Type") {
                  selectedFileType.value = "All Files";
                }

                // Use settings.showFileTypeBottomSheet (unchanged) — adapt callbacks to update Rx vars
                if (selectedFolder.value != null &&
                    selectedFolder.value != "All files") {
                  settings.showFileTypeBottomSheet(
                    context,
                    allFiles.toList(),
                    selectedFolder.value,
                    (filteredFiles, selectedType) {
                      files.assignAll(fileSettings.getFilteredFiles(
                        allFiles: allFiles,
                        folderPath: selectedFolder.value!,
                        fileType: selectedType,
                      ));
                      selectedFileType.value =
                          (selectedType == null || selectedType.isEmpty)
                              ? "All Files"
                              : selectedType;
                    },
                    selectedFileType.value,
                    (newType) {
                      selectedFileType.value = newType ?? "All Files";
                      files.assignAll(fileSettings.getFilteredFiles(
                        allFiles: allFiles,
                        folderPath: selectedFolder.value,
                        fileType: selectedFileType.value,
                      ));
                    },
                  );
                } else {
                  // All files
                  settings.showFileTypeBottomSheet(
                    context,
                    allFiles.toList(),
                    selectedFolder.value,
                    (filteredFiles, selectedType) {
                      files.assignAll(filteredFiles);
                      selectedFileType.value = selectedType ?? "All Files";
                    },
                    selectedFileType.value,
                    (newType) {
                      selectedFileType.value = newType ?? "All Files";
                    },
                  );
                }
              },
              child: Obx(() =>
                  buildImportFunctionalityOptions(selectedFileType.value)),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: GestureDetector(
                onTap: () => showSortOptionsBottomSheet(context, files.toList(),
                        (sortedFiles) {
                      files.assignAll(sortedFiles);
                    }),
                child: buildImportFunctionalityOptions("Sort By")),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire scaffold inside Obx so reactive reads rebuild automatically
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A3D62),
          iconTheme: const IconThemeData(color: Colors.white),
          title: importFiles.isNotEmpty
              ? Text(
                  importFiles.length == 1
                      ? "1 File Selected"
                      : "${importFiles.length} Files Selected",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                )
              : !_isSearching.value
                  ? Text("File",
                      style: GoogleFonts.poppins(color: Colors.white))
                  : TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search files...",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                      onChanged: (query) {
                        if (query.isEmpty) {
                          files.assignAll(allFiles);
                        } else {
                          final q = query.trim().toLowerCase();
                          files.assignAll(allFiles.where((file) => file.path
                              .split('/')
                              .last
                              .toLowerCase()
                              .contains(q)));
                        }
                      },
                    ),
          leading: importFiles.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    importFiles.clear();
                  })
              : _isSearching.value
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        _isSearching.value = false;
                        searchController.clear();
                        files.assignAll(allFiles);
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
          actions: _isSearching.value
              ? []
              : [
                  importFiles.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.done_all, color: Colors.white),
                          onPressed: () {
                            // Select all visible files into importFiles
                            importFiles.assignAll(files);
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            _isSearching.value = true;
                          },
                        ),
                  IconButton(
                    onPressed: () {
                      isGridView.value = !isGridView.value;
                    },
                    icon: Icon(isGridView.value ? Icons.list : Icons.grid_view,
                        color: Colors.white),
                  ),
            PopupMenuButton<String>(
              borderRadius: BorderRadius.circular(0),
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (String result) {
                if (result == 'pickFiles') {
                  settings.pickFilesFromSystemWithAutoFolder(
                      setState, files, context);
                }
              },
              offset: const Offset(0, 40),
              color: Colors.white,
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<String>>[
                // ✅ Open system files item
                PopupMenuItem<String>(
                  height: 25,
                  value: 'pickFiles',
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder, color: Colors.black),
                        Text(
                          'Open System Files',
                          style: GoogleFonts.poppins(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasSdCard.value) // SD Card है तो ही ये option दिखाओ
                // ✅ Show SD card files option
                  PopupMenuItem<String>(
                    height: 25,
                    value: 'toggleSdCardFiles',
                    child: StatefulBuilder(
                      builder: (context, setStatePopup) {
                        return Padding(
                          padding:
                          const EdgeInsets.only(right: 8.0, top: 4.0),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                fillColor:
                                MaterialStateProperty.resolveWith(
                                        (states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return Colors.blue.shade700;
                                      }
                                      return Colors.white;
                                    }),
                                value: showSdCardFiles.value,
                                onChanged: (bool? value) async {
                                  setStatePopup(() {
                                    showSdCardFiles.value = value ?? false;
                                  });
                                  setState(() {
                                    _isLoading.value = true;
                                    selectedFolderDisplayName.value = "All files";
                                    selectedFileType.value = "File Type";
                                    importFiles.clear();  //This is for Resetting Import List and appbar menu Option
                                  });
                                  await loadFiles();
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                              ),
                              Text(
                                "Show SD Card Files",
                                style: GoogleFonts.poppins(
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // ✅ Show hidden files option
                PopupMenuItem<String>(
                  height: 25,
                  value: 'toggleHiddenFiles',
                  child: StatefulBuilder(
                    builder: (context, setStatePopup) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              fillColor: MaterialStateProperty.resolveWith(
                                      (states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.blue.shade700;
                                    }
                                    return Colors.white;
                                  }),
                              value: _showHiddenFiles.value,
                              onChanged: (bool? value) async {
                                setStatePopup(() {
                                  _showHiddenFiles.value = value ?? false;
                                });
                                List<File> updatedFiles = await fileSettings
                                    .getFilesFromDirectory(
                                  Directory('/storage/emulated/0/'),
                                  showHiddenFiles: _showHiddenFiles.value,
                                );
                                setState(() {
                                  files.value = updatedFiles;
                                  _isLoading.value = true;
                                  selectedFolderDisplayName.value = "All files";
                                  selectedFileType.value = "File Type";
                                  importFiles.clear();  //This is for Resetting Import List and appbar menu Option
                                });
                                await loadFiles();
                              },
                              activeColor: Colors.blue,
                              checkColor: Colors.white,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                "Show Hidden Files",
                                style: GoogleFonts.poppins(
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
            buildTopOptionsRow(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: Color(0xFF0A3D62),
                        ))
                      : (files.isEmpty
                          ? Center(
                              child: Text("No files found in ${selectedFolderDisplayName.value}"))
                          : buildFilesView(
                              files: files,
                              importFiles: importFiles,
                              isGridView: isGridView,
                              toggleFileSelection: (File file) {
                                // pass a no-op instead of setState to settings function
                                settings.toggleFileSelection(file, importFiles,
                                    (_) {}, _scrollController);
                              },
                              settings: settings,
                            )),
                  // Import list bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 3, horizontal: 8),
                      child: Obx(() => importListSection(
                            context,
                            importFiles: importFiles,
                            toggleFileSelection: (File file) =>
                                settings.toggleFileSelection(file, importFiles,
                                    (_) {}, _scrollController),
                            importSelectedFiles: () =>
                                settings.importSelectedFiles(
                                    context, importFiles, (_) {}),
                            scrollController: _scrollController,
                            settings: settings,
                          )),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

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
  final FileFetchSettings fileFetchSetting = FileFetchSettings();
  List<String> folderNames = folders.keys.toList();
  folderNames.insert(0, "All files"); // Default option on top

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
                padding: const EdgeInsets.all(7),
                child: const Icon(Icons.folder, size: 23, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Select Folder",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text("Show files from folder",
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.shade400, height: 0.1),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.black26, height: 0.1),
            itemCount: folderNames.length,
            itemBuilder: (context, index) {
              String folderName = folderNames[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                margin: EdgeInsets.zero,
                child: RadioListTile<String>(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  secondary: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.folder,
                        color: selectedFolder == folderName
                            ? Colors.blue
                            : Colors.black,
                        size: 23),
                  ),
                  title: Text(
                    folderName.split('/').last == '0'
                        ? "Internal Storage"
                        : folderName.split('/').last.contains(
                                RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$'))
                            ? "Disk"
                            : folderName.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selectedFolder == folderName
                            ? Colors.blue.shade700
                            : Colors.black87),
                  ),
                  subtitle: Builder(builder: (context) {
                    int fileCount;
                    String storageType = "";

                    if (folderName == "All files") {
                      fileCount = allFiles.length;
                    } else if (folderName.split('/').last == '0') {
                      fileCount = folders['/storage/emulated/0']
                              ?.where((file) =>
                                  file.parent.path == '/storage/emulated/0')
                              .length ??
                          0;
                      storageType = "Internal Storage";
                    } else if (folderName
                        .split('/')
                        .last
                        .contains(RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$'))) {
                      final sdCardRootPath = folderName;
                      fileCount = folders[sdCardRootPath]
                              ?.where(
                                  (file) => file.parent.path == sdCardRootPath)
                              .length ??
                          0;
                      storageType = "SD Card";
                    } else {
                      fileCount = folders[folderName]
                              ?.where((file) => file.parent.path == folderName)
                              .length ??
                          0;
                      storageType =
                          CustomGallerySetting().getStorageType(folderName);
                    }

                    String subtitleText = "$fileCount files";
                    if (storageType.isNotEmpty && folderName != "All files") {
                      subtitleText += " - $storageType";
                    }

                    return Text(subtitleText,
                        style: TextStyle(
                            color: selectedFolder == folderName
                                ? Colors.blue.shade700
                                : Colors.black87));
                  }),
                  value: folderName,
                  groupValue: selectedFolder,
                  onChanged: (value) {
                    if (value != null) {
                      final filteredFiles = fileFetchSetting.getFilteredFiles(
                        allFiles: allFiles,
                        folderPath: value == "0"
                            ? "/storage/emulated/0"
                            : (RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$')
                                    .hasMatch(value.split('/').last)
                                ? value
                                : value),
                        fileType: selectedFileType,
                      );

                      onFolderSelected(value, filteredFiles);
                    }
                  },
                  activeColor: Colors.blue.shade700,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              );
            },
          ),
        )
      ],
    ),
  );
}
