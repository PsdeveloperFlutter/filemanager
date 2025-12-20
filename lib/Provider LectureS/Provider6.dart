import'package:flutter/material.dart';
void main(){
  runApp(MaterialApp(home: value_Listener(),));
}
class value_Listener extends StatelessWidget {
  const value_Listener({super.key});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool>obscureAble=ValueNotifier(false);  //for textfield obscure text
    ValueNotifier<int>valueAble=ValueNotifier<int>(0);
    print("build called \n");
    return Scaffold(
      body:Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ValueListenableBuilder(valueListenable:obscureAble,  builder:(context,value,child){
             return  TextField(
               onTap: (){
                  obscureAble.value=!obscureAble.value;
               },
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    suffixIcon: obscureAble.value?Icon(Icons.visibility_off):Icon(Icons.visibility),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        gapPadding: 10,
                        borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2
                        )
                    ),
                    hintText: "Enter something"
                ),
                obscureText:obscureAble.value ,
              );
            } ),
            ValueListenableBuilder(valueListenable: valueAble, builder: (context,value,child){
              return Text(valueAble.value.toString());
            })
            ,ElevatedButton(onPressed: (){
              valueAble.value++;
            }, child: Icon(Icons.add))
          ],
        ),
      )
    );
  }
}
