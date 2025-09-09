// lib/main.dart
import 'package:flutter/material.dart';
import '../ui/dashboardUi.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardUi(), // Use the widget from your new file
    ),
  );
}