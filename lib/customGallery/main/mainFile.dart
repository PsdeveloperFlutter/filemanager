import'package:flutter/material.dart';

void main(){
MaterialApp(home: MainFile(),);

}
class MainFile extends StatelessWidget {
  const MainFile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (
        Center(child: Text("Main File"),)
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){},child: Icon(Icons.add),),
    );
  }
}