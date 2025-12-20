import 'dart:io';

import 'package:filemanager/StudentManagement/screens/detailsStudentScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../provider/auth_provider.dart';
import 'UiHelper.dart';
import 'attendanceHistory.dart';
import 'settingScreen.dart';

/// ================= CONTROLLERS =================

// Existing controllers
final TextEditingController nameController = TextEditingController();
final TextEditingController classController = TextEditingController();
final TextEditingController rollNoController = TextEditingController();
final TextEditingController ageController = TextEditingController();
final TextEditingController phoneController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController searchController = TextEditingController();

// ✅ NEW: Description controller (OPTIONAL FIELD)
final TextEditingController descriptionController = TextEditingController();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthProviders>().fetchStudentData().then((_) {
        context.read<AuthProviders>().fetchUserSignUpData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          backgroundColor: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  context.read<AuthProviders>().userSignUpData.isNotEmpty
                      ? context.read<AuthProviders>().userSignUpData[0]
                              ['name'] ??
                          ''
                      : '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  context.read<AuthProviders>().userSignUpData.isNotEmpty
                      ? context.read<AuthProviders>().userSignUpData[0]
                              ['email'] ??
                          ''
                      : '',
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Password'),
                subtitle: Text(
                  context
                          .read<AuthProviders>()
                          .userSignUpData[0]['password']
                          .isNotEmpty
                      ? context
                          .read<AuthProviders>()
                          .userSignUpData[0]['password']
                          .toString()
                          .replaceAll(RegExp(r'.'), '*')
                      : '',
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.50),
              Center(
                child: Text(
                    "Developed by Priyanshu Satija \n© 2025 All Rights Reserved",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    )),
              ),
            ],
          )),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
        backgroundColor: Colors.blue,
        title: const Text("Home Screen", style: TextStyle(color: Colors.white)),
      ),

      /// ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          clearControllers(
            nameController,
            classController,
            rollNoController,
            ageController,
            phoneController,
            emailController,
            descriptionController,
          );
          context.read<AuthProviders>().isUpdating = false;
          bottomSheetItem(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xffabfff0)],
          ),
        ),
        child: Column(
          children: [
            /// ================= SEARCH BAR =================
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  context.read<AuthProviders>().searchStudent(value);
                },
                decoration: InputDecoration(
                  hintText: "Search by name, class or rollno etc",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /// ================= STUDENT LIST =================
            Expanded(
              child: Consumer<AuthProviders>(
                builder: (context, provider, child) {
                  if (provider.filteredStudentData.isEmpty) {
                    return const Center(child: Text("No Students Found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.filteredStudentData.length,
                    itemBuilder: (context, index) {
                      final student = provider.filteredStudentData[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return detailsScreen(student: {
                                'name': student.name,
                                'roll': student.rollno,
                                'age': student.age,
                                'className': student.className,
                                'email': student.email,
                                'phone': student.phone,
                                'photo': student.photo,
                                'description': student.description,
                              });
                            }));
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: (student.photo != null &&
                                      student.photo!.isNotEmpty)
                                  ? FileImage(File(student.photo!))
                                  : null,
                              backgroundColor: Colors.blue,
                            ),
                            title: Text(
                              student.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Class: ${student.className}\nRoll No: ${student.rollno}",
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    /// EDIT STUDENT
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.green),
                                      onPressed: () {
                                        nameController.text = student.name;
                                        classController.text =
                                            student.className;
                                        rollNoController.text =
                                            student.rollno.toString();
                                        ageController.text =
                                            student.age.toString();
                                        phoneController.text = student.phone;
                                        emailController.text = student.email;

                                        // ✅ NEW: Set description while editing
                                        descriptionController.text =
                                            student.description ?? '';

                                        provider.isUpdating = true;
                                        provider.updatingStudentId = student.id;

                                        bottomSheetItem(context);
                                      },
                                    ),

                                    /// DELETE STUDENT
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        confirmDeleteOfStudentData(
                                            context, student, provider);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.check_circle_outline,
                                          color: Colors.blue),
                                      tooltip: 'Mark Attendance / View',
                                      onPressed: () {
                                        bottomSheetAttendance(
                                            context, student.id, student.name);
                                        // Optionally: navigate to history
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AttendanceHistoryScreen(
                                                        studentId: student.id,
                                                        studentName:
                                                            student.name)));
                                      },
                                      icon: Icon(Icons.add_alert),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> bottomSheetAttendance(
      BuildContext context, int studentId, String studentName) async {
    final colors = Theme.of(context).colorScheme;
    DateTime selectedDate = DateTime.now();
    bool isPresent = true; // default

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Attendance - $studentName",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                title: Text("Date: ${selectedDate.toIso8601String().split('T')[0]}", style: TextStyle(color: Colors.black),),
          onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: isPresent,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            isPresent = value;
                          });
                        }
                      },
                    ),
                    const Text("Present"),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: false,
                      groupValue: isPresent,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            isPresent = value;
                          });
                        }
                      },
                    ),
                    const Text("Absent"),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    String dateStr =
                        selectedDate.toIso8601String().split('T')[0];
                    await DbHelper.instance.markAttendance(
                        studentId: studentId,
                        date: dateStr,
                        isPresent: isPresent);
                    Get.back();
                    Get.snackbar(
                      "Success",
                      "Attendance marked successfully",
                      backgroundColor: colors.primary,
                      colorText: Colors.white,
                    );
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= BOTTOM SHEET =================
Future<void> bottomSheetItem(BuildContext context) {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
              /// TOP INDICATOR
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
              Center(
                child: Text(
                  context.read<AuthProviders>().isUpdating
                      ? "Update Student Details"
                      : "Add Student Details",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              /// NAME
              buildTextField(
                controller: nameController,
                label: "Student Name",
                icon: Icons.person,
                validator: (value) =>
                    value!.isEmpty ? "Name is required" : null,
              ),

              /// CLASS
              buildTextField(
                controller: classController,
                label: "Class",
                icon: Icons.class_sharp,
                validator: (value) =>
                    value!.isEmpty ? "Class is required" : null,
              ),

              /// ROLL NO
              buildTextField(
                controller: rollNoController,
                label: "Roll No",
                icon: Icons.account_circle_sharp,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Roll No is required" : null,
              ),

              /// AGE
              buildTextField(
                controller: ageController,
                label: "Age",
                icon: Icons.account_circle_sharp,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Age is required" : null,
              ),

              /// PHONE
              buildTextField(
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

              /// EMAIL
              buildTextField(
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

              /// ✅ DESCRIPTION (OPTIONAL)
              buildTextField(
                controller: descriptionController,
                label: "Description (Optional)",
                icon: Icons.description,
              ),

              const SizedBox(height: 20),

              /// PHOTO BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthProviders>().pickFromCamera();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthProviders>().pickFromGallery();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// SAVE / UPDATE BUTTON
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
                    if (formKey.currentState!.validate() &&
                        context.read<AuthProviders>().isUpdating == false) {
                      await context.read<AuthProviders>().addInsert(
                            name: nameController.text.trim(),
                            className: classController.text.trim(),
                            rollno: int.parse(rollNoController.text),
                            age: int.parse(ageController.text),
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            photo: context
                                .read<AuthProviders>()
                                .studentImage
                                ?.path,
                            description:
                                descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                          );

                      Get.back();
                      Get.snackbar(
                        "Success",
                        "Student added successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else if (formKey.currentState!.validate() &&
                        context.read<AuthProviders>().isUpdating == true) {
                      final studentId = context
                          .read<AuthProviders>()
                          .StudentData
                          .firstWhere((student) =>
                              student.name == nameController.text.trim())
                          .id;

                      await context.read<AuthProviders>().updateStudentData(
                            studentId,
                            nameController.text.trim(),
                            classController.text.trim(),
                            int.parse(rollNoController.text),
                            int.parse(ageController.text),
                            emailController.text.trim(),
                            phoneController.text.trim(),
                            context.read<AuthProviders>().studentImage?.path,
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                          );

                      context.read<AuthProviders>().isUpdating = false;
                      Get.back();
                      clearControllers(
                        nameController,
                        classController,
                        rollNoController,
                        ageController,
                        phoneController,
                        emailController,
                        descriptionController,
                      );

                      Get.snackbar(
                        "Success",
                        "Student updated successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Text(
                    context.read<AuthProviders>().isUpdating
                        ? "Update Student"
                        : "Save Student",
                    style: const TextStyle(
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
