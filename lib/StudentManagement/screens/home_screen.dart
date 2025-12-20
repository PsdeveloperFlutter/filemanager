import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthProviders>().fetchStudentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // important
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Home Screen"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          bottomSheetItem(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xffabfff0),
            ],
          ),
        ),
        child: Consumer<AuthProviders>(
          builder: (context, provider, child) {
            if (provider.StudentData.isEmpty) {
              return const Center(
                child: Text(
                  "No Students Added Yet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.StudentData.length,
              itemBuilder: (context, index) {
                final student = provider.StudentData[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Class: ${student.className}\nRoll No: ${student.rollno}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        context.read<AuthProviders>().deleteStudent(student.id);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> bottomSheetItem(BuildContext context) {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  return Get.bottomSheet(
    isScrollControlled: true,
    Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Indicator
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Add Student Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Name
              _buildTextField(
                controller: nameController,
                label: "Student Name",
                icon: Icons.person,
                validator: (value) =>
                    value!.isEmpty ? "Name is required" : null,
              ),

              /// Class
              _buildTextField(
                controller: classController,
                label: "Class",
                icon: Icons.class_sharp,
                validator: (value) =>
                    value!.isEmpty ? "Class is required" : null,
              ),

              /// Roll No
              _buildTextField(
                controller: rollNoController,
                label: "Roll No",
                icon: Icons.account_circle_sharp,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Roll No is required" : null,
              ),

              /// Age
              _buildTextField(
                controller: ageController,
                label: "Age",
                icon: Icons.account_circle_sharp,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Age is required" : null,
              ),

              /// Phone
              _buildTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Phone number is required";
                  } else if (value.length != 10) {
                    return "Enter valid 10-digit number";
                  }
                  return null;
                },
              ),

              /// Email
              _buildTextField(
                controller: emailController,
                label: "Email ID",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Email is required";
                  } else if (!GetUtils.isEmail(value)) {
                    return "Enter valid email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// Photo Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Take Photo (Optional)
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Choose from Gallery (Optional)
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await context.read<AuthProviders>().addInsert(
                            name: nameController.text.trim(),
                            className: classController.text.trim(),
                            rollno: int.parse(rollNoController.text),
                            age: int.parse(ageController.text),
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            photo: null, // optional
                          );

                      Get.back();

                      Get.snackbar(
                        "Success",
                        "Student added successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: const Text(
                    "Save Student",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildTextField({
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
