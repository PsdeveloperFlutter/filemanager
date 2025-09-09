import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'customGalleryUi.dart';


class DashboardUi extends StatefulWidget {
  const DashboardUi({super.key});

  @override
  State<DashboardUi> createState() => _DashboardUiState();
}

class _DashboardUiState extends State<DashboardUi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> importedFolders = []; // To store folder info

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchImportedFolders(); // Load folders on Home tab load
  }

  /// ✅ Folder Fetch Logic - Returns list of folder paths
  Future<List<String>> getImportedFolders() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory baseImportDir = Directory(p.join(appDir.path, "ImportedFiles"));
    if (await baseImportDir.exists()) {
      List<FileSystemEntity> entities = baseImportDir.listSync();
      return entities
          .where((e) => FileSystemEntity.isDirectorySync(e.path))
          .map((e) => e.path)
          .toList();
    } else {
      return [];
    }
  }

  /// ✅ Fetch Folders + Files inside each folder
  Future<void> fetchImportedFolders() async {
    List<String> folderPaths = await getImportedFolders();
    List<Map<String, dynamic>> tempList = [];

    for (String folderPath in folderPaths) {
      Directory folder = Directory(folderPath);
      List<FileSystemEntity> files = folder.listSync();

      tempList.add({
        "folderName": p.basename(folderPath), // Only folder name
        "files": files
            .where((e) => FileSystemEntity.isFileSync(e.path))
            .map((e) => File(e.path))
            .toList(), // All files inside folder
      });
    }

    setState(() {
      importedFolders = tempList;
    });
  }

  /// ✅ UI Widget to display folders and files
  Widget buildImportedFolderList() {
    if (importedFolders.isEmpty) {
      return Center(child: Text("No imported folders found"));
    }

    return ListView.builder(
      itemCount: importedFolders.length,
      itemBuilder: (context, index) {
        var folder = importedFolders[index];
        String folderName = folder["folderName"];
        List<File> files = folder["files"];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          elevation: 2,
          child: ExpansionTile(
            leading: Icon(Icons.folder, color: Colors.orange),
            title: Text(folderName), // Folder Name
            children: files.map((file) {
              String fileName = p.basename(file.path);
              return ListTile(
                leading: Icon(Icons.insert_drive_file, color: Colors.green),
                title: Text(fileName),
                subtitle: Text(file.path), // File full path
                onTap: () {
                  // You can open file or show preview here
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Open file import UI and refresh after returning
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomGalleryApp()),
          );
          if (refresh == true) {
            fetchImportedFolders(); // ✅ Refresh only after successful import
          }

        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
        title: const Text(
          'Doc Scanner',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          labelStyle: const TextStyle(fontSize: 12),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          controller: _tabController,
          tabs: const [
            Tab(text: 'Home', icon: Icon(Icons.home, color: Colors.white)),
            Tab(text: 'PDF Editor', icon: Icon(Icons.edit, color: Colors.white)),
            Tab(text: 'PDF Tools', icon: Icon(Icons.build, color: Colors.white)),
            Tab(text: 'Import ID Photo', icon: Icon(Icons.photo, color: Colors.white)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ✅ Home Tab: Show folders + files
          buildImportedFolderList(),

          // Other Tabs remain same
          Center(child: Text('PDF Editor Page')),
          Center(child: Text('PDF Tools Page')),
          Center(child: Text('Import ID Photo Page')),
        ],
      ),
    );
  }
}
