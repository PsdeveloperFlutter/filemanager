import'package:flutter/material.dart';
import 'package:provider/provider.dart';
class work extends StatelessWidget {
  work({super.key});
  ValueNotifier<int> valueAble=ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
       ValueListenableBuilder(valueListenable:valueAble , builder: (context,value,child){
         return Text(valueAble.value.toString());
       })
      ],),
      floatingActionButton: FloatingActionButton(onPressed: (){
        valueAble.value++;
      },child:Icon(Icons.add)),
    );
  }
}
void main(){
  runApp(MaterialApp(home: work(),));
}
