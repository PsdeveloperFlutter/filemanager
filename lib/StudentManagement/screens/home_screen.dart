import 'dart:io';

import 'package:filemanager/StudentManagement/screens/detailsStudentScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../provider/auth_provider.dart';
import '../textTovoice/textToVoice.dart';
import 'UiHelper.dart';
import 'addHolidayScreen.dart';
import 'attendanceHistory.dart';

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
  late FlutterTts futureTts;

  @override
  void initState() {
    super.initState();
    futureTts = FlutterTts();
    Future.microtask(() {
      context.read<AuthProviders>().loadProfileImage();
      context.read<AuthProviders>().fetchStudentData().then((_) {
        context.read<AuthProviders>().fetchUserSignUpData();
        speakWelcomeMessage(context, futureTts);
      });
    });
  }

  @override
  void dispose() {
    futureTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Drawer(
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    currentAccountPicture: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text("Camera"),
                                onTap: () {
                                  Navigator.pop(context);
                                  context
                                      .read<AuthProviders>()
                                      .pickProfileFromCamera();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo),
                                title: const Text("Gallery"),
                                onTap: () {
                                  Navigator.pop(context);
                                  context
                                      .read<AuthProviders>()
                                      .pickProfileFromGallery();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Consumer<AuthProviders>(
                        builder: (context, provider, _) {
                          return CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            backgroundImage: provider.profileImage != null
                                ? FileImage(provider.profileImage!)
                                : null,
                            child: provider.profileImage == null
                                ? const Icon(Icons.person, color: Colors.blue)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        "Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        context.read<AuthProviders>().userSignUpData.isNotEmpty
                            ? context
                                .read<AuthProviders>()
                                .userSignUpData[0]['password']
                                .toString()
                                .replaceAll(RegExp(r'.'), '•')
                            : '',
                        style: const TextStyle(
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddHolidayScreen()),
                      );
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Add Holiday",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.40),
                  Center(
                    child: Text(
                        "Developed by Priyanshu Satija \n© 2025 All Rights Reserved",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        )),
                  ),
                ],
              ),
            )),
        appBar: AppBar(
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
              /// Displays all students with profile, basic info and quick actions
              Expanded(
                child: Consumer<AuthProviders>(
                  builder: (context, provider, child) {
      
                    /// Show loader while data is loading
                    if (provider.filteredStudentData.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
      
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: provider.filteredStudentData.length,
                      itemBuilder: (context, index) {
                        final student = provider.filteredStudentData[index];
      
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
      
                          /// Tap whole card to open student details screen
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => detailsScreen(
                                    student: {
                                      'name': student.name,
                                      'roll': student.rollno,
                                      'age': student.age,
                                      'className': student.className,
                                      'email': student.email,
                                      'phone': student.phone,
                                      'photo': student.photo,
                                      'description': student.description,
                                    },
                                  ),
                                ),
                              );
                            },
      
                            child: Padding(
                              padding: const EdgeInsets.all(12),
      
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
      
                                  /// ================= STUDENT PROFILE IMAGE =================
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage: (student.photo != null &&
                                        student.photo!.isNotEmpty)
                                        ? FileImage(File(student.photo!))
                                        : null,
                                    child: (student.photo == null ||
                                        student.photo!.isEmpty)
                                        ? const Icon(Icons.person,
                                        size: 30, color: Colors.blue)
                                        : null,
                                  ),
      
                                  const SizedBox(width: 12),
      
                                  /// ================= STUDENT BASIC INFO =================
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
      
                                        /// Student Name
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
      
                                        const SizedBox(height: 4),
      
                                        /// Class & Roll No
                                        Text(
                                          "Class: ${student.className} • Roll No: ${student.rollno}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
      
                                        const SizedBox(height: 8),
      
                                        /// ================= QUICK ACTION BUTTONS =================
                                        Row(
                                          children: [
      
                                            /// Edit Student
                                            IconButton(
                                              tooltip: "Edit Student",
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.green),
                                              onPressed: () {
                                                nameController.text = student.name;
                                                classController.text = student.className;
                                                rollNoController.text =
                                                    student.rollno.toString();
                                                ageController.text =
                                                    student.age.toString();
                                                phoneController.text = student.phone;
                                                emailController.text = student.email;
                                                descriptionController.text =
                                                    student.description ?? '';
      
                                                provider.isUpdating = true;
                                                provider.updatingStudentId = student.id;
      
                                                bottomSheetItem(context);
                                              },
                                            ),
                                            /// Mark Attendance
                                            IconButton(
                                              tooltip: "Mark Attendance",
                                              icon: const Icon(Icons.check_circle_outline,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                bottomSheetAttendance(
                                                    context, student.id, student.name);
                                              },
                                            ),
      
                                            /// View Attendance History
                                            IconButton(
                                              tooltip: "Attendance History",
                                              icon: const Icon(Icons.history,
                                                  color: Colors.deepPurple),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AttendanceHistoryScreen(
                                                          studentId: student.id,
                                                          studentName: student.name,
                                                          studentImage: student.photo,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  /// Delete Student
                                  IconButton(
                                    tooltip: "Delete Student",
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      confirmDeleteOfStudentData(
                                          context, student, provider);
                                    },
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
                  title: Text(
                    "Date: ${selectedDate.toIso8601String().split('T')[0]}",
                    style: TextStyle(color: Colors.black),
                  ),
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
