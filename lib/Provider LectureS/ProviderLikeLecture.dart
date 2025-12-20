import 'package:filemanager/Provider%20LectureS/myFavouritescreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Provider_Change(),
      child: const MaterialApp(
        home: FavouriteScreen(),
      ),
    ),
  );
}

class Provider_Change extends ChangeNotifier {
  List<int> selected_item = [];

  void result(int index) {
    if (selected_item.contains(index)) {
      selected_item.remove(index); // FIXED
    } else {
      selected_item.add(index);
    }
    notifyListeners();
  }
}

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favourite App"),
        actions: [
          InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return  myfavouriteScreen();
                }));
              },
              child: Icon(Icons.favorite))
        ],
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          return Consumer<Provider_Change>(builder: (context,provider,child){
            return ListTile(
              onTap: () {
                context.read<Provider_Change>().result(index);
              },
              leading: Text("${index + 1}"),
              trailing: Icon(
                provider.selected_item.contains(index)
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                color: Colors.red,
              ),
            );
          });
        },
      ),
    );
  }
}
