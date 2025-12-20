import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import 'ProviderLikeLecture.dart';
class myfavouriteScreen extends StatefulWidget {
  const myfavouriteScreen({super.key});

  @override
  State<myfavouriteScreen> createState() => _myfavouriteScreenState();
}

class _myfavouriteScreenState extends State<myfavouriteScreen> {
  @override
  Widget build(BuildContext context) {
    final favouriteProvider=Provider.of<Provider_Change>(context);
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
        itemCount: favouriteProvider.selected_item.length,
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
