import 'package:flutter/material.dart';

void main() {
  runApp(const CzanixApp());
}

class CzanixApp extends StatelessWidget {
  const CzanixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Czanix Boilerplate',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD4A843),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Czanix Boilerplate — Flutter\nClean Architecture • Riverpod • Offline-first'),
        ),
      ),
    );
  }
}
