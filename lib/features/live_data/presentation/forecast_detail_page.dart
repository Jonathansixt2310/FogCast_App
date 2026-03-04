import 'package:flutter/material.dart';

class ForecastDetailPage extends StatelessWidget {
  const ForecastDetailPage({super.key});

  static const bg = Color(0xFF2B4544);
  static const tile = Color(0xFF5E8886);
  static const tileDark = Color(0xFF2F4F4F);
  static const white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: white),
        centerTitle: true,
        title: const Text(
          'FOGCAST',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [

            /// --- GROSSE FORECAST KACHEL ---
            Container(
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// DATUM PILL
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: tileDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Donnerstag, 05. März 2026',
                      style: TextStyle(
                        color: white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// TEMPERATUR + ICON
                  Row(
                    children: [

                      const Text(
                        '12°',
                        style: TextStyle(
                          color: white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Icon(
                        Icons.nightlight_round,
                        color: Colors.amber,
                        size: 36,
                      ),

                      const Spacer(),

                      /// BUTTON RECHTS
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: tileDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.thermostat, color: white),
                            SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_down, color: white),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 22),

                  /// CHART TILE
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFF274847),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Temperatur Chart (placeholder)',
                        style: TextStyle(color: white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}