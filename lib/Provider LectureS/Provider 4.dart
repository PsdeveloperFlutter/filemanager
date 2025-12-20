import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderLecture4 extends ChangeNotifier {
  ProviderLecture4(){
    loadItems();  // Load items when the provider is initialized
  }
  List items = [];
  List filteredItems = [];

  // Load Items from Shared Preferences
  void loadItems()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    items=prefs.getStringList('my_items')??[];
    filteredItems=List.from(items);
    notifyListeners();
  }
  // Save Items to Shared Preferences
  Future<void> saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_items', items.cast<String>());
  }


  void addItem(String item) {
    items.add(item);
    filteredItems = List.from(items);
    saveItems();
    notifyListeners();
  }


  void removeItem(int index) {
    items.removeAt(index);
    filteredItems = List.from(items);
    saveItems();
    notifyListeners();
  }

  /// Update Functionality with Provider Lecture
  void updateItem(dynamic items, dynamic newItem) {
    int index = this.items.indexOf(items);
    if (index != -1) {
      this.items[index] = newItem;
      filteredItems = List.from(this.items);
      saveItems();          // <-- ALWAYS SAVE
      notifyListeners();
    }
  }

 // Search Functionality with Provider Lecture
  void searchItems(String query) {
    if (query.isEmpty) {
      filteredItems = List.from(items);
    } else {
      filteredItems = items
          .where((item) =>
              item.toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }


  // Delete All Functionality with Provider Lecture
  void deleteAll(){
    filteredItems.clear();
    items.clear();
    notifyListeners();
  }
}





//UI Class
class uiCode extends StatelessWidget {
  uiCode({super.key});

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Lecture with List")
      ,actions: [
        IconButton(
            onPressed: (){
              context.read<ProviderLecture4>().saveItems();
              },
            icon: Icon(Icons.save)
        ),
        IconButton(onPressed: (){
          context.read<ProviderLecture4>().deleteAll();
        }, icon: Icon(Icons.delete_forever_sharp))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search…",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<ProviderLecture4>().searchItems(value);
              },
            ),
          ),


          Consumer(builder: (context, provider, child) {
            final pro = Provider.of<ProviderLecture4>(context);
            return Expanded(
                child: ListView.builder(
                    itemCount: pro.filteredItems.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 3,
                        child: ListTile(
                            leading: CircleAvatar(
                              child: Text("${index + 1}"),
                            ),
                            title: Text(pro.filteredItems[index].toString()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      context
                                          .read<ProviderLecture4>()
                                          .updateItem(
                                              pro.filteredItems[index],
                                              controller.text.isNotEmpty
                                                  ? controller.text
                                                  : pro.filteredItems[index]);
                                    },
                                    icon: Icon(Icons.edit)),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) =>
                                            showDialogBox(context, index));
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            )),
                      );
                    }));
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  height: 50,
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Enter Item",
                    ),
                    controller: controller,
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    Provider.of<ProviderLecture4>(context, listen: false)
                        .addItem(controller.text);
                  },
                  child: Text("Add"))
            ],
          )
        ],
      ),
    );
  }
}

Widget showDialogBox(BuildContext context, int index) {
  return AlertDialog(
    title: Text("Delete Item"),
    content: Text("Are you sure you want to delete this item?"),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text("Cancel"),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          Provider.of<ProviderLecture4>(context, listen: false)
              .removeItem(index);
        },
        child: Text("Delete"),
      ),
    ],
  );
}

void main() {
  runApp(
    ChangeNotifierProvider(
        create: (_) => ProviderLecture4(), child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: uiCode())),
  );
}
