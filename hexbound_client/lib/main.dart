import 'package:flutter/material.dart';
import 'game/hex_map_widget.dart'; // New Engine

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hexbound VTT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HexMapWidget(),
      // home: const Scaffold(body: Center(child: Text("Test Build"))),
    );
  }
}
