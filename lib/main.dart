import 'package:flutter/material.dart';
import 'package:fullstack/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FullStack',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        accentColor: Colors.white,
      ),
      home: HomePage(),
    );
  }
}
