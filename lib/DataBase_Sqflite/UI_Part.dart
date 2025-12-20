import 'package:flutter/material.dart';

import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool isLoading = true;
  final DBHelper dbHelper = DBHelper.getInstance;

  // Controllers
  final TextEditingController controller_name = TextEditingController();
  final TextEditingController controller_age = TextEditingController();
  final TextEditingController controller_email = TextEditingController();

  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();

    loadData();
  }

  // Fetch data from DB
  void loadData() async {
    final data = await dbHelper.fetchData();
    isLoading = false;
    setState(() {
      userList = data;
    });
  }

  // Insert data
  void insertUser() async {
    if (controller_name.text.isEmpty ||
        controller_age.text.isEmpty ||
        controller_email.text.isEmpty) {
      return;
    }

    await dbHelper.insertData(
      controller_name.text,
      int.parse(controller_age.text),
      controller_email.text,
    );

    controller_name.clear();
    controller_age.clear();
    controller_email.clear();

    loadData(); // refresh list
  }

  void deleteUser(int id) async {
    await dbHelper.deleteData(id);
    loadData(); // refresh list
  }

  void updateUser(int id, String name, int age, String email) async {
    await dbHelper.updateData(id, name, age, email);
    loadData(); // refresh list
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Sqflite Database Example"),
        ),
        body: Column(
          children: [
            // LIST
            Expanded(
              child: userList.isEmpty
                  ? Center(
                      child: Text("No Data Found"),
                    )
                  : ListView.builder(
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        final item = userList[index];
                        return Card(
                          child: ListTile(
                            trailing: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        deleteUser(item['id']);
                                      },
                                      child: Icon(Icons.delete)),
                                  SizedBox(width: 5),
                                  InkWell(
                                      onTap: () {
                                        // Update functionality can be added here
                                        updateUser(
                                          item['id'],
                                          controller_name.text.isEmpty
                                              ? item['name']
                                              : controller_name.text,
                                          controller_age.text.isEmpty
                                              ? item['age']
                                              : int.parse(controller_age.text),
                                          controller_email.text.isEmpty
                                              ? item['email']
                                              : controller_email.text,
                                        );
                                      },
                                      child: Icon(Icons.edit))
                                ],
                              ),
                            ),
                            title: Text(item['name']),
                            subtitle: Text(
                                "Age: ${item['age']} | Email: ${item['email']}"),
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    controller: controller_name,
                    decoration: InputDecoration(
                      hintText: "Enter Name",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: controller_age,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter Age",
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: controller_email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: insertUser,
                      child: Text("Save Data"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
