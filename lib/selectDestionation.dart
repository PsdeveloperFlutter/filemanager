import 'dart:io';
import 'package:filemanager/fileBrowserController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class SelectDestinationSheet extends StatelessWidget {
  final FileBrowserController controller = Get.find<FileBrowserController>();
  final String mode;
  SelectDestinationSheet({required this.mode});
  @override
  Widget build(BuildContext context) {
    final isCopyMode = mode == "copy";
    return Container(
      height: Get.height * 0.85,
      padding: const EdgeInsets.all(12.0),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔝 Title Bar
              _buildHeader(isCopyMode),
              const SizedBox(height: 10),
              // 🔙 Back Navigation & Path
              _buildBackNav(),
              const SizedBox(height: 8),
              // 💾 Internal Storage Shortcut
              _buildInternalStorageButton(),
              const SizedBox(height: 8),
              // 📂 Folder List
              _buildFolderList(),
              const SizedBox(height: 12),
              // ➕ Create & Action Button
              _buildBottomButtons(isCopyMode),
            ],
          )),
    );
  }

  Widget _buildHeader(bool isCopyMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isCopyMode ? "Select Copy Destination" : "Select Destination",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildBackNav() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final parent = controller.currentDestinationDir.value.parent;
            if (parent.existsSync()) {
              controller.browseDestinationFolder(parent);
            }
          },
        ),
        Expanded(
          child: Text(
            "Path: ${controller.currentDestinationDir.value.path}",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInternalStorageButton() {
    return ElevatedButton.icon(
      onPressed: () {
        final root = Directory('/storage/emulated/0');
        controller.selectedDestination.value = root;
        controller.browseInternalStorage();
      },
      icon: const Icon(Icons.sd_storage),
      label: const Text("Internal Storage"),
    );
  }

  Widget _buildFolderList() {
    return Expanded(
      child: ListView.builder(
        itemCount: controller.destinationFolders.length,
        itemBuilder: (context, index) {
          final folder = controller.destinationFolders[index];
          final folderName = folder.path.split('/').last;
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(folderName),
            onTap: () {
              controller.selectedDestination.value = folder;
              controller.browseDestinationFolder(folder);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(bool isCopyMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: controller.createFolderInDestination,
          icon: const Icon(Icons.create_new_folder),
          label: const Text("Create Folder"),
        ),
        ElevatedButton.icon(
          onPressed:
              isCopyMode ? controller.executeCopy : controller.executeMove,
          icon: Icon(isCopyMode ? Icons.copy : Icons.check),
          label: Text(isCopyMode ? "Copy Here" : "Select Here"),
        ),
      ],
    );
  }
}
