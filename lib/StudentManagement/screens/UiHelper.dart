import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../db/db_helper.dart';

/// ================= TEXTFIELD WIDGET =================
Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

/// ================= CLEAR CONTROLLERS =================
void clearControllers(
  TextEditingController nameController,
  TextEditingController classController,
  TextEditingController rollNoController,
  TextEditingController ageController,
  TextEditingController phoneController,
  TextEditingController emailController,
  TextEditingController descriptionController,
) {
  nameController.clear();
  classController.clear();
  rollNoController.clear();
  ageController.clear();
  phoneController.clear();
  emailController.clear();
  descriptionController.clear(); // ✅ NEW
}
///------------------ CONFIRM DELETE STUDENT DATA -----------------
confirmDeleteOfStudentData(BuildContext context, student, provider) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text(
        'Are you sure you want to delete ${student.name}? This action cannot be undo whole data will remove.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child:  Text('Cancel',style: GoogleFonts.habibi()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style:  GoogleFonts.habibi(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    provider.deleteStudent(student.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Student deleted successfully',style: GoogleFonts.habibi())),
    );
  }
}
 ///------------------ CONFIRM DELETE ATTENDANCE DATA -----------------
confirmDeleteOfAttendanceData(
  BuildContext context,
  Map<String, Object?> record,
  Function loadAttendance,
    ){
  showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
  title: Text('Confirm delete',style: GoogleFonts.habibi()),
  content: Text('Are you sure you want to delete this attendance record?',style: GoogleFonts.habibi()),
  actions: [
  TextButton(
  onPressed: () => Navigator.of(context).pop(false),
  child:  Text('Cancel',style: GoogleFonts.habibi()),
  ),
  TextButton(
  onPressed: () => Navigator.of(context).pop(true),
  child:  Text('Delete',style: GoogleFonts.habibi()),
  ),
  ],
  ),
  ).then((confirmed) {
  if (confirmed == true) {
  DbHelper.instance.deleteAttendance(record['id'] as int).then((value) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text("Attendance record deleted",style: GoogleFonts.habibi())),
  );
  loadAttendance();
  });
  }
  });

}
void showSortDialog(
    BuildContext context,
    List<Map<String, dynamic>> attendanceList,
    Function(List<Map<String, dynamic>>) onSorted, /// Callback for Sorted List
    ) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Sort Attendance',style: GoogleFonts.habibi()),
        content:  Text('Choose sorting option',style: GoogleFonts.habibi()),
        actions: [

          /// PRESENT FIRST
          TextButton(
            onPressed: () {
              final sorted =
              List<Map<String, dynamic>>.from(attendanceList);

              sorted.sort((a, b) =>
                  (b['isPresent'] as int)
                      .compareTo(a['isPresent'] as int));

              Navigator.pop(dialogContext);
              onSorted(sorted);
            },
            child:  Text('Present First',style: GoogleFonts.habibi()),
          ),

          /// ABSENT FIRST
          TextButton(
            onPressed: () {
              final sorted =
              List<Map<String, dynamic>>.from(attendanceList);

              sorted.sort((a, b) =>
                  (a['isPresent'] as int)
                      .compareTo(b['isPresent'] as int));

              Navigator.pop(dialogContext);
              onSorted(sorted);
            },
            child: Text('Absent First',style: GoogleFonts.habibi(),),
          ),
        ],
      );
    },
  );
}
