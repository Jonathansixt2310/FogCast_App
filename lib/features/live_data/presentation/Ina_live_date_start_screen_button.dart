import 'package:flutter/material.dart';
import 'Ina_dashboard_page.dart';

class Ina_live_data_start_screen_button extends StatelessWidget {
  const Ina_live_data_start_screen_button({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit),
      tooltip: 'Ina Dashboard',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Ina_dashboard_page()),
        );
      },
    );
  }
}