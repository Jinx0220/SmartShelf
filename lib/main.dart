import 'package:flutter/material.dart';
import 'package:smartshelf/loginandregister_screen.dart';

void main() {
  runApp(MyHomePage());
}
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AI38",
      home: LoginAndRegister(),
    );
  }
}
