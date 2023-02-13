// import 'package:accessible_text_view/accessible_text_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Flutter Fonts Example'),
        ),
        body: const Center(
          child: Text('hello'),
          // child: AccessibleTextView(
          //   html: 'This is a test to see if font loading works.',
          // ),
        ),
      ),
    );
  }
}
