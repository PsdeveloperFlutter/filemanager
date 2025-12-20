import 'package:filemanager/StudentManagement/db/db_helper.dart';
import 'package:filemanager/StudentManagement/model/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProviders with ChangeNotifier {
  bool _isLoggedIn = false;
  bool obscurePasswordforSignUp = true;
  bool obscureConfirmPasswordforSignUp = true;
  bool obscurePasswordforLogin = true;
  List<StudentModel> StudentData = [];

  ///Fetch data from Student Data
  Future<void> fetchStudentData() async {
    final db = await DbHelper.instance.getDB();
    final List<Map<String, dynamic>> result =
    await db.query(DbHelper.tableName);

    StudentData = result
        .map((e) => StudentModel.fromMap(e))
        .toList();

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
    String? photo,
  }) async {
    await DbHelper.instance.insertData(
      name: name,
      rollno: rollno,
      age: age,
      className: className,
      email: email,
      phone: phone,
      photo: photo,
    );
    await fetchStudentData();
  }
Future<void>deleteStudent(int id)async{
    await DbHelper.instance.deleteData(id);
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
}
