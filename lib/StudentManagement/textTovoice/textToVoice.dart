import 'package:filemanager/StudentManagement/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

Future<void>speakWelcomeMessage(BuildContext context , FlutterTts flutterTts)async{
  final provider=context.read<AuthProviders>();
  if(provider.userSignUpData.isEmpty)return;
  String name=provider.userSignUpData[0]['name']??'User';
  await flutterTts.setLanguage('en-IN');
  await flutterTts.setSpeechRate(0.45);
  await flutterTts.setPitch(1.0);
  String message="Welcome $name to Student Management System";
  await flutterTts.speak(message);

}