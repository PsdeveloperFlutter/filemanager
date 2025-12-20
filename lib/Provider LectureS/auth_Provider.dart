import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
class AuthProvider extends ChangeNotifier {
  bool isLoading=false;
  bool get loading=>isLoading;
  setloading(bool value){
    isLoading=value;
    notifyListeners();
  }
  void login(String email, String password)async{
    setloading(true);
    try{
      final uri="https://reqres.in/api/login";
     Response response=await post(Uri.parse(uri),
     body: {
       'email':email,
       'password':password
     }
     );
     if(response.statusCode==200){
        print("Login Successful \n ${response.body} \n ");
        setloading(false);
     }
     else{
      print("Login Failed \n ${response.body} \n ");
      setloading(false);
     }
    }catch(e){
      setloading(false);
      print("${e.toString()} \n ");
    }
  }
}