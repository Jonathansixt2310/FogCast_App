import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';

class ForecastDetailPage extends ConsumerStatefulWidget {
  const ForecastDetailPage({super.key});

  @override
  ConsumerState<ForecastDetailPage> createState() => _ForecastDetailPageState();
}

class _ForecastDetailPageState extends ConsumerState<ForecastDetailPage> {
  String _selectedMetric = 'Temperatur';

  static const bg = Color(0xFF2B4544);
  static const tile = Color(0xFF5E8886);
  static const tileDark = Color(0xFF2F4F4F);
  static const chartBg = Color(0xFF274847);
  static const white = Colors.white;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);
    final forecast = state.forecast ?? <ForecastDto>[];

    // --- MORGEN (00:00–23:59) ---
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
    final end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    final tomorrowData = forecast
        .where((f) => !f.date.isBefore(start) && !f.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // --- Metric-Konfiguration (ein Chart, unterschiedliche y-Quelle) ---
    final metric = _MetricConfig.fromKey(_selectedMetric);

    // Spots: x = Stunde (inkl. Minuten), y = gewählte Metrik
    final spots = <FlSpot>[];
    for (final f in tomorrowData) {
      final x = f.date.hour + (f.date.minute / 60.0);
      final y = metric.valueOf(f);

      if (y != null && y.isFinite) {
        spots.add(FlSpot(x, y));
      }
    }

    // Min/Max fürs Scaling
    double? minY;
    double? maxY;
    for (final s in spots) {
      minY = (minY == null) ? s.y : (s.y < minY! ? s.y : minY);
      maxY = (maxY == null) ? s.y : (s.y > maxY! ? s.y : maxY);
    }
    if (minY != null && maxY != null && minY == maxY) {
      minY = minY! - 1;
      maxY = maxY! + 1;
    }

    final headlineValue = (spots.isNotEmpty)
        ? '${spots.first.y.round()}${metric.unitShort}'
        : '--${metric.unitShort}';
    final ForecastDto? firstOfDay = tomorrowData.isNotEmpty ? tomorrowData.first : null;
    final String emoji = _weatherEmojiFromCode(firstOfDay?.weatherCode);

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
            // --- GROSSE FORECAST KACHEL ---
            Container(
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DATUM PILL (morgen)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: tileDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _formatGermanDate(tomorrow),
                        style: const TextStyle(
                          color: white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // VALUE + ICON + DROPDOWN
                  Row(
                    children: [
                      Text(
                        headlineValue,
                        style: const TextStyle(
                          color: white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                      const Spacer(),
                      _MetricDropdown(
                        value: _selectedMetric,
                        onChanged: (v) => setState(() => _selectedMetric = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // CHART TILE
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: chartBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: (spots.length < 2)
                        ? Center(
                      child: Text(
                        'Keine ${metric.label}daten für morgen',
                        style: const TextStyle(color: white),
                      ),
                    )
                        : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 23.99,
                        minY: minY,
                        maxY: maxY,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(color: white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 6,
                              getTitlesWidget: (value, meta) {
                                final h = value.round();
                                return Text(
                                  '${h.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(color: white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
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

/// Dropdown-Pill
class _MetricDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _MetricDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const pillColor = Color(0xFF2B4544);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(999),
      ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160), // ggf. 150/170 testen
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          value: value,
          dropdownColor: pillColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
              items: const [
                DropdownMenuItem(
                  value: 'Temperatur',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thermostat, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Temperatur', overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Luftfeuchte',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Luftfeuchte', overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Wind',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Wind', overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
          ),
        ),
      ),
    );
  }
}

/// Metric-Logik zentral (damit du nicht 3 Charts bauen musst)
class _MetricConfig {
  final String key;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String unitShort;
  final double? Function(ForecastDto f) valueOf;

  const _MetricConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.unitShort,
    required this.valueOf,
  });

  static _MetricConfig fromKey(String key) {
    switch (key) {
      case 'Luftfeuchte':
        return _MetricConfig(
          key: 'Luftfeuchte',
          label: 'Luftfeuchte',
          icon: Icons.water_drop,
          iconColor: Colors.lightBlueAccent,
          unitShort: '%',
          // Dafür muss ForecastDto "humidity" haben (double)
          valueOf: (f) => f.humidity,
        );
      case 'Wind':
        return _MetricConfig(
          key: 'Wind',
          label: 'Wind',
          icon: Icons.air,
          iconColor: Colors.white,
          unitShort: 'm/s',
          // Dafür muss ForecastDto "windSpeed" haben (double) – falls du es später hinzufügst.
          // Bis dahin gib null zurück (dann erscheinen keine Spots).
          valueOf: (f) => f.windSpeed,
        );
      case 'Temperatur':
      default:
        return _MetricConfig(
          key: 'Temperatur',
          label: 'Temperatur',
          icon: Icons.thermostat,
          iconColor: Colors.amber,
          unitShort: '°',
          valueOf: (f) => f.temperature,
        );
    }
  }
}

String _formatGermanDate(DateTime d) {
  const w = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const m = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
  ];
  return '${w[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}. ${m[d.month - 1]} ${d.year}';
}
String _weatherEmojiFromCode(int? code) {
  const iconMap = {
    0: "☀️",
    1: "🌤️",
    2: "⛅",
    3: "☁️",
    45: "🌫️",
    48: "🌫️",
    51: "🌦️",
    53: "🌦️",
    55: "🌦️",
    56: "🌧️",
    57: "🌧️",
    61: "🌧️",
    63: "🌧️",
    65: "🌧️",
    71: "🌨️",
    73: "🌨️",
    75: "🌨️",
    77: "❄️",
    80: "🌦️",
    81: "🌦️",
    82: "🌧️",
    95: "⛈️",
    96: "⛈️",
    99: "⛈️",
  };
  if (code == null) return "❔";
  return iconMap[code] ?? "❔";
}