import 'dart:math';

import 'package:filemanager/StudentManagement/db/db_helper.dart';
import 'package:filemanager/StudentManagement/model/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
class AuthProviders with ChangeNotifier {
  bool _isLoggedIn = false;
  bool obscurePasswordforSignUp = true;
  bool obscureConfirmPasswordforSignUp = true;
  bool obscurePasswordforLogin = true;
  List<StudentModel> StudentData = [];
  List<StudentModel> filteredStudentData = [];
  bool isUpdating = false;
  int? updatingStudentId;
  File?studentImage;
  File? profileImage;  ///Profile Image
  String? profileImagePath;///Profile Image Path

  final ImagePicker _picker=ImagePicker();
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  /// User SignUp Data List for showing at drawer
  List<Map<String, dynamic>> userSignUpData = [];


  ///userSignUpData fetch
   Future<void>fetchUserSignUpData()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String?name=prefs.getString('name');
    String?email=prefs.getString('email');
    String?password=prefs.getString('password');
    userSignUpData.clear();
    if(name!=null && email!=null && password!=null){
      userSignUpData.add({
        'name':name,
        'email':email,
        'password':password,
      });
    }
    notifyListeners();
   }
  /// Load saved theme
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('theme');

    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Change theme
  Future<void> changeTheme(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (mode == ThemeMode.light) {
      await prefs.setString('theme', 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString('theme', 'dark');
    } else {
      await prefs.setString('theme', 'system');
    }

    _themeMode = mode;
    notifyListeners();
  }
  ///Check signUp data
  Future<bool>checkSignUpData()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String?name=prefs.getString('name');
    String?email=prefs.getString('email');
    String?password=prefs.getString('password');
    if(name!=null && email!=null && password!=null){
      return true;
    }else{
      return false;
    }
  }
  ///Pick Image From Gallery
  Future<void>pickFromGallery()async{
    final XFile? pickedImage=await _picker.pickImage(source: ImageSource.gallery,imageQuality: 80);
    if(pickedImage!=null){
      studentImage=File(pickedImage.path);
      notifyListeners();
    }
  }
  ///Pick Image From Camera
  Future<void>pickFromCamera()async{
    final XFile?pickedImage=await _picker.pickImage(source: ImageSource.camera,imageQuality: 80);
    pickedImage!=null?studentImage=File(pickedImage.path):null;
    notifyListeners();
  }

  ///Fetch data from Student Data
  Future<void> fetchStudentData() async {
    final db = await DbHelper.instance.getDB();
    final List<Map<String, dynamic>> result =
        await db.query(DbHelper.studentTable);

    StudentData = result.map((e) => StudentModel.fromMap(e)).toList();
    // ✅ ADD THIS LINE
    filteredStudentData = StudentData;
    notifyListeners();
  }

  /// ---------------- SEARCH ----------------
  void searchStudent(String query) {
    if (query.isEmpty) {
      filteredStudentData = StudentData;
    } else {
      filteredStudentData = StudentData.where((student) {
        return student.name.toLowerCase().contains(query.toLowerCase()) ||
            student.className.toLowerCase().contains(query.toLowerCase()) ||
            student.rollno.toString().contains(query) ||
            student.phone.contains(query) ||
            student.email.toLowerCase().contains(query.toLowerCase()) ||
            student.age.toString().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  /// ---------------- INSERT STUDENT ----------------
  Future<void> addInsert({
    required String name,
    required int rollno,
    required int age,
    required String className,
    required String email,
    required String phone,
    String? photo, String? description,
  }) async {
    await DbHelper.instance.insertStudent(
      name: name,
      rollno: rollno,
      age: age,
      className: className,
      email: email,
      phone: phone,
      photo: photo,
      description: description,
    );
    await fetchStudentData();
  }

  Future<void> deleteStudent(int id) async {
    await DbHelper.instance.deleteStudent(id);
    await fetchStudentData();
  }

  ///Update  Student Data
  Future<void> updateStudentData(int id, String name, String  classes,
      int rollno, int age, String email, String phone, String? photo,String ? description) async {
    await DbHelper.instance
        .updateStudent(id:id, name: name,className:  classes,rollno:  rollno, age: age,email:  email,phone:  phone,
        photo: photo,description: description);
    await fetchStudentData();
  }

  void setObscurePasswordLogin(bool value) {
    obscurePasswordforLogin = value;
    notifyListeners();
  }

  bool get isLoggedIn => _isLoggedIn;

  /// Toggle Password Visibility
  void setObscureText(bool value) {
    obscurePasswordforSignUp = value;
    notifyListeners();
  }

  void setObscureText2(bool value) {
    obscureConfirmPasswordforSignUp = value;
    notifyListeners();
  }

  /// Check Login Status on App Start
  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners();
  }

  /// Signup Method
  Future<void> signUp(String name, String email, String password) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('password', password);

      await prefs.setBool('isLoggedIn', true); // ✅ FIX

      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Sign Up Failed: $e');
    }
  }

  /// Login Method
  Future<bool> loginUser(String email, String password) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? storedEmail = prefs.getString('email');
      String? storedPassword = prefs.getString('password');
       print("Stored Email: $storedEmail, Stored Password: $storedPassword \n");
      if (storedEmail == email && storedPassword == password) {
        _isLoggedIn = true;
        await prefs.setBool('isLoggedIn', true);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  /// Logout Method
  Future<void> logOutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  Future<void> pickProfileFromCamera() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      profileImage = File(image.path);
      await saveProfileImagePath(image.path);
      notifyListeners();
    }
  }

  Future<void> pickProfileFromGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      profileImage = File(image.path);
      await saveProfileImagePath(image.path);
      notifyListeners();
    }
  }
   ///SaveProfileImageIntoPath
  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', path);
  }
  ///GetProfileImageFromPath
  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    profileImagePath = prefs.getString('profile_image');

    if (profileImagePath != null) {
      profileImage = File(profileImagePath!);
    }
    notifyListeners();
  }



}
