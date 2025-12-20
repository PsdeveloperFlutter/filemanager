import 'dart:io';
import 'package:flutter/material.dart';

class detailsScreen extends StatelessWidget {
  final Map<String, dynamic> student;

  const detailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Details"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            /// PROFILE IMAGE
            CircleAvatar(
              radius: 60,
              backgroundImage: (student['photo'] != null &&
                  student['photo'].toString().isNotEmpty)
                  ? FileImage(File(student['photo']))
                  : null,
              backgroundColor: Colors.blue,
              child: student['photo'] == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 20),

            /// NAME
            Text(
              student['name'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _infoTile("Class", student['className'] ?? ''),
            _infoTile("Roll No", student['roll'].toString()),
            _infoTile("Age", student['age'].toString()),
            _infoTile("Phone", student['phone'] ?? ''),
            _infoTile("Email", student['email'] ?? ''),

            /// DESCRIPTION (OPTIONAL)
            if (student['description'] != null &&
                student['description'].toString().isNotEmpty)
              _infoTile("Description", student['description']),
          ],
        ),
      ),
    );
  }

  /// Reusable Tile
  Widget _infoTile(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}
