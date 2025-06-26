// import 'package:flutter/material.dart';
// import 'AuthService.dart';
// import 'MainFile.dart';
//
// class SetPinScreen extends StatelessWidget{
//  final TextEditingController _pinController=TextEditingController();
//   final AuthService _authService=AuthService();
//   SetPinScreen();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Set App Pin"),),
//       body:Padding(padding: const EdgeInsets.all(20),
//       child:
//         Column(
//           children: [
//             TextField(
//               controller: _pinController,
//               obscureText: true,
//               maxLength: 4,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: "Enter 4-digit PIN"
//               ),
//             ),
//             SizedBox(height: 20,),
//             ElevatedButton(onPressed: ()async{
//               if(_pinController.text.length==4){
//                 await _authService.SetPin(_pinController.text);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => FileManagerScreen()),
//                 );
//               }
//             }, child: Text("Save Pin"))
//           ],
//         ),),
//     );
//   }
// }