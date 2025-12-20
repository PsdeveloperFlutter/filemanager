import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProivderwithList extends ChangeNotifier {
  List items = [];

  void addItem(dynamic item) {
    items.add(item);
    notifyListeners();
  }

  void removeItem(dynamic item) {
    items.remove(item);
    notifyListeners();
  }

  void updateItem(dynamic newItem, int index) {
    items[index] = newItem;
    notifyListeners();
  }
}

class ProviderLecture2 extends StatefulWidget {
  ProviderLecture2({super.key});

  @override
  State<ProviderLecture2> createState() => _ProviderLecture2State();
}

class _ProviderLecture2State extends State<ProviderLecture2> {
  TextEditingController controller = TextEditingController();
  int indexvalue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Lecture with List")),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ProivderwithList>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          indexvalue = index;
                          controller.text = provider.items[index];
                        });
                      },
                      child: ListTile(
                        title: Text(provider.items[index].toString()),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // TextField
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter item",
              ),
            ),
          ),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Provider.of<ProivderwithList>(context, listen: false)
                      .addItem(controller.text);
                },
                child: Text("Add"),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<ProivderwithList>(context, listen: false)
                      .removeItem(controller.text);
                },
                child: Text("Remove"),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<ProivderwithList>(context, listen: false)
                      .updateItem(controller.text, indexvalue);
                },
                child: Text("Update"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProivderwithList(),
      child: MaterialApp(
        home: ProviderLecture2(),
      ),
    ),
  );
}
