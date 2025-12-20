import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../settings/customGallerySetting.dart';

final settings = CustomGallerySetting();

/// Import Button UI
Widget importListSection(
    BuildContext context, {
      required List<File> importFiles,
      required Function(File file) toggleFileSelection,
      required VoidCallback importSelectedFiles,
      required ScrollController scrollController,
      required CustomGallerySetting settings,
    }) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      backgroundColor: importFiles.isEmpty
          ? Colors.grey.withOpacity(0.2)
          : const Color(0xFF0A3D62),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: importSelectedFiles,
    child: Text(
      "Import",
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

/// Dropdown-style option widget
Widget buildImportFunctionalityOptions(String text, {double maxWidth = 140}) {
  bool isWhiteBg = (text == 'All Files' ||
      text == "All files" ||
      text == 'Sort By' ||
      text == 'File Type');

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isWhiteBg ? Colors.white : Colors.blue.shade400,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.grey.shade400, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: GoogleFonts.poppins(
              color: isWhiteBg ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_drop_down,
          color: isWhiteBg ? Colors.black : Colors.white,
          size: 18,
        ),
      ],
    ),
  );
}

// Store last selected criteria globally
String? lastSelectedCriteria;

/// Sort File Logic using pure GetX reactivity (Obx)
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
      ].obs;

      // ✅ Sort Icons
      final List<String> iconsStrings = [
        'assets/icons/calendar.webp',
        'assets/icons/sort-by-alphabet.webp',
        'assets/icons/expand.webp',
      ];

      // ✅ Use reactive RxString instead of StatefulBuilder
      final RxString selectedCriteria =
          (lastSelectedCriteria ?? "By Date").obs;

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          children: [
            // ✅ Title Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: Colors.grey.shade300, width: 1),
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
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "Select sort by",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 0.1, color: Colors.grey.shade300),

            // ✅ Radio List for Sorting Options wrapped with Obx
            Expanded(
              child: Obx(
                    () => ListView.separated(
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
                      child: Obx((()=>RadioListTile<String>(
                        secondary: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Image.asset(
                            iconsStrings[index],
                            width: 22,
                            height: 22,
                            color: selectedCriteria.value == criteria
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                        title: Text(
                          criteria,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: selectedCriteria.value == criteria
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                        value: criteria,
                        groupValue: selectedCriteria.value,
                        onChanged: (value) {
                          selectedCriteria.value = value!;
                          lastSelectedCriteria = value;
                        },
                        activeColor: Colors.blue,
                        controlAffinity: ListTileControlAffinity.trailing,
                      )))
                    );
                  },
                ),
              ),
            ),

            // ✅ Ascending / Descending Buttons wrapped in Obx
            Obx(
                  () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => settings.sortFiles(
                        selectedCriteria.value,
                        true,
                        files,
                        onSorted,
                        context,
                        lastSelectedCriteria,
                      ),
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      label: Text(
                        selectedCriteria.value == "By Name"
                            ? "A to Z"
                            : selectedCriteria.value == "By Date"
                            ? "Oldest"
                            : "Smallest",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        backgroundColor: const Color(0xFF0A3D62),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => settings.sortFiles(
                        selectedCriteria.value,
                        false,
                        files,
                        onSorted,
                        context,
                        lastSelectedCriteria,
                      ),
                      icon:
                      const Icon(Icons.arrow_downward, color: Colors.white),
                      label: Text(
                        selectedCriteria.value == "By Name"
                            ? "Z to A"
                            : selectedCriteria.value == "By Date"
                            ? "Newest"
                            : "Largest",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
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
            ),
          ],
        ),
      );
    },
  );
}
