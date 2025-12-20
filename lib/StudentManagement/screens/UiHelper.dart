import 'package:flutter/material.dart';

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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    provider.deleteStudent(student.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student deleted successfully')),
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
  title: const Text('Confirm delete'),
  content: const Text('Are you sure you want to delete this attendance record?'),
  actions: [
  TextButton(
  onPressed: () => Navigator.of(context).pop(false),
  child: const Text('Cancel'),
  ),
  TextButton(
  onPressed: () => Navigator.of(context).pop(true),
  child: const Text('Delete'),
  ),
  ],
  ),
  ).then((confirmed) {
  if (confirmed == true) {
  DbHelper.instance.deleteAttendance(record['id'] as int).then((value) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Attendance record deleted")),
  );
  loadAttendance();
  });
  }
  });

}