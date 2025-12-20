import 'dart:convert';

import 'package:filemanager/getxPractice/todomodal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Controller
class TodoController extends GetxController {
  var todos = <Todo>[].obs;

  @override
  // void onInit() async {
  //   super.onInit();
  //   await loadTodos(); // Load todos when controller is initialized
  // }
  void onInit() {
    super.onInit();
    debugPrint("Todo Controller Initialized");
  }

  @override
  void onReady() {
    loadTodos();
    super.onReady();
    debugPrint("Todo Controller is Ready");
  }

  @override
  void onClose() {
    super.onClose();
    debugPrint("Todo Controller Closed");
  }

  // ✅ Add todo function
  void addTodo(String title, String description, bool isDone) {
    if (title.isEmpty || description.isEmpty) {
      Get.snackbar("Error", "Please enter both title and description",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
      return;
    }
    final todo = Todo(title: title, description: description, isDone: isDone,details: description);
    todos.add(todo);
  }

  // ✅ Update todo function
  void updateTodo(int index, String title, String description, bool isDone) {
    if (title.isEmpty || description.isEmpty) {
      Get.snackbar("Error", "Please enter both title and description",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
      return;
    }
    final updatedTodo =
        Todo(title: title, description: description, isDone: isDone,details: description);
    todos[index] = updatedTodo;
  }
  //This is for SaveTodos to the SharedPreferences
  Future<void> saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> todoList =
          todos.map((todo) => jsonEncode(todo.toJson())).toList();
      await prefs.setStringList('todos', todoList);
      Get.snackbar("Success", "Todos saved successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to save todos.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  //This is for LoadTodos from the SharedPreferences
  Future<void> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? todoList = prefs.getStringList('todos');
    if (todoList != null) {
      todos.value = todoList.map((e) => Todo.fromJson(jsonDecode(e))).toList();
    }
  }
}

// ✅ Main Entry Point
void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: TodoApp(),
  ));
}

// ✅ Main UI
class TodoApp extends StatefulWidget {
  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final TextEditingController controllerText = TextEditingController();
  final TextEditingController controllerdes = TextEditingController();
  final TodoController todoCtrl = Get.put(TodoController());

  @override
  void dispose() {
    controllerText.dispose();
    controllerdes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todo App with GetX"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildTodoTextfield(controllerText, "Enter Todo Title"),
            SizedBox(height: 10),
            buildTodoTextfield(controllerdes, "Enter Todo Description"),

            SizedBox(height: 10),

            // ✅ Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    todoCtrl.addTodo(
                        controllerText.text, controllerdes.text, false);
                    controllerText.clear();
                    controllerdes.clear();
                  },
                  child: Text("Add Todo"),
                ),
                ElevatedButton(
                    onPressed: () {
                      todoCtrl.saveTodos(); // Save todos to SharedPreferences
                    },
                    child: Text("Save"))
              ],
            ),
            SizedBox(height: 20),

            // ✅ Reactive Todo List
            Expanded(
              child: GetX<TodoController>(builder: (todoCtrl) {
                return ListView.builder(
                  itemCount: todoCtrl.todos.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                          onTap: () {
                            controllerText.text = todoCtrl.todos[index].title;
                            controllerdes.text =
                                todoCtrl.todos[index].description;
                          },
                          onLongPress: () {
                            todoCtrl.todos.removeAt(index);
                          },
                          title: Text(todoCtrl.todos[index].title),
                          subtitle: Text(todoCtrl.todos[index].description),
                          trailing: ElevatedButton(
                              onPressed: () => todoCtrl.updateTodo(
                                  index,
                                  controllerText.text,
                                  controllerdes.text,
                                  false),
                              child: Icon(Icons.update)),
                          leading: Checkbox(
                            value: todoCtrl.todos[index].isDone,
                            onChanged: (value) {
                              todoCtrl.todos[index].isDone = value ?? false;
                              todoCtrl.todos.refresh();
                            },
                          )),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildTodoTextfield(TextEditingController controllerText, String value) {
  return // ✅ TextField to enter Todo
      TextField(
    controller: controllerText,
    decoration: InputDecoration(
      border: OutlineInputBorder(),
      labelText: value,
    ),
  );
}
