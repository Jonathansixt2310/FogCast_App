import 'package:flutter/material.dart';

class ExpertPage extends StatelessWidget {
  const ExpertPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'EXPERTENMODUS',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Hier kommt später die Experten-Startseite rein.',
            style: TextStyle(
              color: white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}