// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/dashboardUi.dart';

void main() {
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardUi(), // Use the widget from your new file
    ),
  );
}