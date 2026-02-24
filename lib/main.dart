import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/live_data/presentation/start_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FogCastApp(),
    ),
  );
}

class FogCastApp extends StatelessWidget {
  const FogCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FogCast',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const start_page(), // Unser erster Screen
    );
  }
}