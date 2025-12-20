class StudentModel {
  final int id;
  final String name;
  final int rollno;
  final int age;
  final String className;
  final String email;
  final String phone;
  final String? photo;

  StudentModel({
    required this.id,
    required this.name,
    required this.rollno,
    required this.age,
    required this.className,
    required this.email,
    required this.phone,
    this.photo,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      name: map['name'],
      rollno: map['rollno'],
      age: map['age'],
      className: map['className'],
      email: map['email'],
      phone: map['phone'],
      photo: map['photo'], // can be null
    );
  }
}
