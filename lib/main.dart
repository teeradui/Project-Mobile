import 'package:flutter/material.dart';
import 'package:mobile_project/GroceryPage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery & Meal Planner',
      home: const GroceryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}