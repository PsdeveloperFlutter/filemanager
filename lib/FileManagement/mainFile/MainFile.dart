import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:filemanager/FileManagement/appLockUi/LockScreen.dart';
import 'package:filemanager/FileManagement/privacyScreen/privacyScreen.dart';
import 'package:filemanager/FileManagement/projectSetting/AuthService.dart';
import 'package:filemanager/FileManagement/uiComponents/uiUtility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../gestureUI/settingGesture.dart';
import 'filemanagerScreen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

//This is the Code For the Starting of the App
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = FlutterSecureStorage();
  final _authService = AuthService();
  final uiObject = uiUtility();

  @override
  void initState() {
    super.initState();
  }

  Future<Widget> _decideStartScreen() async {
    final lockOption =
        await _authService.getStoredLockOption(); // yeh await karo!
    if (lockOption == 'pin') {
      final pin = await _authService.getPin();
      if (pin == null) {
        return FileManagerScreen();
      } else {
        return LockScreen();
      }
    } else if (lockOption == 'screenLock' && mounted) {
      // Added 'mounted' check
      // It's important to check if the widget is still in the tree
      // before interacting with its context, especially in async methods.
      uiObject.showBottomSheets(this.context); // Show biometric options
      return FileManagerScreen(); // Return a default screen while bottom sheet is shown
    } else {
      return FileManagerScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _decideStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          return snapshot.data ?? FileManagerScreen();
        },
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// This is the Code For the File Manager Screen
class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => FileManagerScreenState();
}

class FileManagerScreenState extends State<FileManagerScreen>
    with WidgetsBindingObserver {
  bool shouldLock = false;
  List<FileSystemEntity> allItems = [];
  AuthService authService = AuthService();
  bool privacyEnable = false;
  bool isSelectionMode = false;
  List<FileSystemEntity> selectedItems = [];
  List<FileSystemEntity> currentlyDraggingItems = [];
  bool isDragging = false;
  String? hoverTargetPath;
  bool isGridView = false;
  bool isDragg = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Request permissions and check privacy after UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissionsAndFetchFiles();
      await checkPrivacyOption();
      fetchFolderContent();
      // Ensure the widget is still mounted before calling checkLockOption
      // to prevent errors if the widget is disposed before the async operation completes.
      if (mounted) await checkLockOption();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 📲 App lifecycle events: handle screen lock/resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      shouldLock = true;
    } else if (state == AppLifecycleState.resumed && shouldLock) {
      shouldLock = false;
      _handleAppUnlock();
    }
  }

  // 🔐 Check user privacy setting
  Future<void> checkPrivacyOption() async {
    final value = await authService.getPrivacyLockOption();
    privacyEnable = value == 'true';
    debugPrint("Privacy Enabled: $privacyEnable");
  }

  // 🔐 Initial check when app starts
  Future<void> checkLockOption() async {
    if (!privacyEnable) return;

    final lockOption = await authService.getStoredLockOption();

    if (lockOption == 'screenLock') {
      final isAvailable = await authService.isBiometricTrulyAvailable();
      if (isAvailable) {
        // Ensure context is still valid before using it.
        if (navigatorKey.currentContext != null) {
          uiObject.showBottomSheets(navigatorKey.currentContext!);
        }
      } else {
        debugPrint("Biometric not available");
      }
    } else if (lockOption == 'pin') {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => LockScreen(),
      ));
    }
  }

  // 🔄 Handle app resume from screen lock
  void _handleAppUnlock() async {
    if (!privacyEnable) return;

    final lockOption = await authService.getStoredLockOption();

    if (lockOption == 'screenLock') {
      final isAvailable = await authService.isBiometricTrulyAvailable();
      if (isAvailable) {
        // Ensure context is still valid.
        if (navigatorKey.currentContext != null)
          uiObject.showBottomSheets(navigatorKey.currentContext!);
      }
    } else if (lockOption == 'pin') {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => LockScreen(),
      ));
    }
  }

  // Note: didChangeAppLifeCycleState seems to be a typo and might conflict with didChangeAppLifecycleState.
  // If it's intended to be an override, it should match the framework's method signature exactly.
  // For now, I'm commenting it out as it might be redundant or incorrectly implemented.
  /* @override
  void didChangeAppLifeCycleState(AppLifecycleState state) {
    // ... existing logic ...
  } */

  //request permission and fetch
  Future<void> _requestPermissionsAndFetchFiles() async {
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdk = androidInfo.version.sdkInt;
    bool isGranted = false;

    // 🔹 Handle permission based on SDK version
    if (sdk >= 33) {
      var photos = await Permission.photos.request();
      var videos = await Permission.videos.request();
      var audio = await Permission.audio.request();
      var manage = await Permission.manageExternalStorage.request();

      isGranted = photos.isGranted ||
          videos.isGranted ||
          audio.isGranted ||
          manage.isGranted;
    } else if (sdk > 30) {
      var manage = await Permission.manageExternalStorage.request();
      isGranted = manage.isGranted;
    } else {
      var storage = await Permission.storage.request();
      isGranted = storage.isGranted;
    }

    // 🔹 Fallback: Open settings if not granted
    if (!isGranted) {
      debugPrint("Permission denied. Opening settings.");
      if (mounted) {
        await openAppSettings();
        setState(() => allItems = []);
      }
      return;
    }

    // 🔹 First try: App-specific directory
    Directory? appDir = await getExternalStorageDirectory();
    if (appDir != null && await appDir.exists()) {
      List<FileSystemEntity> appFiles = appDir.listSync();
      debugPrint("App-specific directory: ${appDir.path}");
      for (var item in appFiles) {
        debugPrint(item.path);
      }
      if (mounted) {
        setState(() => allItems = appFiles);
      }
    }

    // 🔹 Try root directory if permission allows
    if ((sdk > 30 && await Permission.manageExternalStorage.isGranted) ||
        (sdk <= 30 && await Permission.storage.isGranted)) {
      Directory rootDir = Directory("/storage/emulated/0");
      if (await rootDir.exists()) {
        List<FileSystemEntity> rootFiles = rootDir.listSync();
        debugPrint("Root directory: ${rootDir.path}");
        for (var item in rootFiles) {
          debugPrint(item.path);
        }
        if (mounted) {
          setState(() => allItems = rootFiles);
        }
      } else {
        debugPrint("Root directory does not exist or can't access.");
      }
    }
  }

  //For Fetching the Folders
  Future<void> fetchFolderContent() async{
    final dir = Directory(
        "/storage/emulated/0"); // Example path, replace with actual logic if needed
    if (dir.existsSync()) {
      List<FileSystemEntity> items = dir.listSync();

      items.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        allItems = items;
        selectedItems.clear();
      });
    }
  }



  Future<void> movesFileToFolder(
      List<FileSystemEntity> files,
      Directory targetFolder,
      BuildContext context,
      int len,
      Directory item) async {
    for (final file in files) {
      try {
        final filename = basename(file.path);
        final newPath = join(targetFolder.path, filename);
        await file.rename(newPath);

        Future.delayed(Duration(milliseconds: 1000), () async {
          await fetchFolderContent();
          Flushbar(
            title: 'Successfully',
            message: len == 0
                ? '${len + 1} Document Move Successfully'
                : len == 1
                ? ' $len Document Move Successfully'
                : '$len Documents Move Successfully',
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orangeAccent,
            icon: Icon(
              Icons.check,
              color: Colors.black,
            ),
          ).show(context); // 👈 यहां show(context) call किया
        });
        setState(() {
          selectedItems.clear();
          isSelectionMode = false;
        });
      } catch (e) {
        debugPrint("Error moving file: $e");
      }
    }
  }

  Future<void> createFolder(BuildContext context, path) async {
    TextEditingController folderNameController = TextEditingController();
    String? errorText; // For feedback inside the dialog
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                      title: Text("Create a New Folder"),
                      content: TextField(
                        controller: folderNameController,
                        decoration: InputDecoration(
                          hintText: "Enter Folder Name",
                          errorText: errorText,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            folderNameController.clear();
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            String newFolderName =
                                folderNameController.text.trim();
                            if (newFolderName.isNotEmpty) {
                              final folder = Directory("$path/$newFolderName");
                              if (!await folder.exists()) {
                                await folder.create();
                                fetchFolderContent();
                                folderNameController.clear();
                                Navigator.of(context).pop();
                              } else {
                                uiObject.flushBars("Error", "Error Occur",
                                    Colors.red, context);
                              }
                            }
                          },
                          child: Text("Create"),
                        )
                      ]));
        });
  }

  //This Below Code is for the Drag and Drop Functionality of the File Manager
  Widget buildDraggableItems(int index, BuildContext context) {
    final item = allItems[index];
    final isFolder = item is Directory;
    final isSelected = selectedItems.any((e) => e.path == item.path);

    return DragTarget<List<FileSystemEntity>>(
      onWillAcceptWithDetails: (dragged) => isFolder,
      onAccept: (dragged) async {
        if (isFolder) {
          debugPrint("\n This statement Is work make sure of that  1");
          await movesFileToFolder(
              dragged, item, context, selectedItems.length, item);

        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return LongPressDraggable<List<FileSystemEntity>>(
          data: selectedItems.isEmpty ? [item] : selectedItems,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              height: 40,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "${selectedItems.isEmpty ? 1 : selectedItems.length} File${(selectedItems.length <= 1) ? '' : 's'}",
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            setState(() {
              isDragging = true;
            });
            print(
                "Drag started with: ${selectedItems.map((e) => e.path).toList()}");
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              selectedItems.clear();
              isSelectionMode = false;
              isDragg = false;
            });
          },
          onDragEnd: (_) {
            setState(() {
              selectedItems.clear();
              isDragging = false;
              isDragg = false;
            });
          },
          child: AnimatedScale(
            filterQuality: FilterQuality.high,
            scale: (isDragging && isSelected) ? 1.10 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Card(
              elevation: 1,
              color: isHighlighted && isFolder
                  ? Colors.greenAccent.shade200
                  : Colors.white,
              child: SizedBox(
                width: 40,
                child: ListTile(
                  onTap: () {
                    if (isSelectionMode && !isFolder) {
                      setState(() {
                        if (isSelected) {
                          selectedItems.removeWhere((e) => e.path == item.path);
                        } else {
                          selectedItems.add(item);
                        }
                      });
                    } else if (isFolder) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FileManagerScreenSub(path: item.path),
                        ),
                      );
                    } else {
                      OpenFilex.open(item.path); // ✅ Open file on tap
                    }
                  },
                  onLongPress: !isSelectionMode && !isFolder
                      ? () {
                          setState(() {
                            isSelectionMode = true;
                            if (!isSelected) {
                              selectedItems.add(item);
                            }
                          });
                        }
                      : null,
                  leading: isSelectionMode && !isFolder
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedItems.add(item);
                              } else {
                                selectedItems
                                    .removeWhere((e) => e.path == item.path);
                              }
                            });
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Icon(
                            isFolder ? Icons.folder : Icons.insert_drive_file,
                            color: Colors.green,
                            size: 25,
                          ),
                        ),
                  title: Text(
                    basename(item.path),
                    style: TextStyle(
                      fontWeight: (isSelected && isSelectionMode)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: (isSelected && isSelectionMode)
                          ? Colors.blue
                          : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    isFolder ? 'Folder' : 'File',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

//This Below Function is for the Moving of the File to the Folder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          Directory? dir = await getExternalStorageDirectory();
          createFolder(context, dir!.path);
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(

          title: isSelectionMode == false
              ? Text("File Manager")
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelectionMode = false;
                      selectedItems.clear();
                    });
                  },
                  child: Icon(
                    Icons.cancel,
                    color: Colors.green,
                  )),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return privacyScreen(); //PrivacyScreen();
                  }));
                },
                icon: Icon(Icons.settings))
          ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () { Scaffold.of(context).openDrawer(); },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Text("File Manager Options")),
            Divider(),
            ListTile(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return SettingGesture();
                }));
              },
              leading:Icon(Icons.gesture,color: Colors.orangeAccent.shade700,),
              title: Text(
                "Gesture Settings",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
      body: ListView.builder(
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            return buildDraggableItems(index, context);
          }),
    );
  }
}
