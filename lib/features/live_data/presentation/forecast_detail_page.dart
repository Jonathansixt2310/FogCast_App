import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';

class ForecastDetailPage extends ConsumerStatefulWidget {
  // Auswahl des Tages in 7  Tage Vorhersage
  final DateTime selectedDate;
  const ForecastDetailPage({super.key, required this.selectedDate});

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

    // --- GEWÄHLTEN TAG BERECHNEN (00:00–23:59) ---
    // Wir nutzen jetzt widget.selectedDate anstatt "tomorrow"
    final targetDate = widget.selectedDate;
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final dayData = forecast // Umbenannt von tomorrowData zu dayData
        .where((f) => !f.date.isBefore(start) && !f.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 1. Filtern für die stündliche Liste
    final now = DateTime.now();
    final hourlyItems = dayData.where((f) {
      if (targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day) {
        return f.date.isAfter(now) || f.date.isAtSameMomentAs(now);
      }
      return true;
    }).toList();

    // --- Metric-Konfiguration ... ---
    final metric = _MetricConfig.fromKey(_selectedMetric);

    final spots = <FlSpot>[];
    for (final f in dayData) {
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
    // HIER: dayData statt tomorrowData verwenden!
    final ForecastDto? firstOfDay = dayData.isNotEmpty ? dayData.first : null;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. DATUM PILL ---
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: tileDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatGermanDate(targetDate),
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. VERTIKALE STÜNDLICHE VORHERSAGE ---
            const Text(
              'Stündliche Vorschau',
              style: TextStyle(
                color: white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Wir nutzen hier eine Column statt ListView, damit alles
            // gemeinsam im SingleChildScrollView scrollt.
            Column(
              children: hourlyItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HourlyVerticalTile(
                    item: item,
                    emoji: _weatherEmojiFromCode(item.weatherCode),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // --- 3. CHART BEREICH ---
            Container(
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMetric,
                        style: const TextStyle(
                          color: white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _MetricDropdown(
                        value: _selectedMetric,
                        onChanged: (v) => setState(() => _selectedMetric = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: chartBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: (spots.length < 2)
                        ? const Center(child: Text('Keine Daten', style: TextStyle(color: white)))
                        : LineChart(
                      LineChartData(
                        // ... deine bestehende LineChartData Konfiguration ...
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.white,
                            dotData: const FlDotData(show: false),
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
                DropdownMenuItem(
                  value: 'Niederschlag',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grain, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Niederschlag', overflow: TextOverflow.ellipsis),
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
      case 'Niederschlag':
        return _MetricConfig(
          key: 'Niederschlag',
          label: 'Niederschlag',
          icon: Icons.grain,
          iconColor: Colors.lightBlueAccent,
          unitShort: 'mm',
          valueOf: (f) => f.precipitation,
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

class _HourlyVerticalTile extends StatelessWidget {
  final ForecastDto item;
  final String emoji;

  const _HourlyVerticalTile({required this.item, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E8886), // Deine 'tile' Farbe
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // 1. Uhrzeit
          SizedBox(
            width: 45,
            child: Text(
              "${item.date.hour.toString().padLeft(2, '0')}:00",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. Wetter-Icon
          SizedBox(width: 35, child: Text(emoji, style: const TextStyle(fontSize: 22))),

          // 3. Temperatur
          SizedBox(
            width: 45,
            child: Text(
              "${item.temperature.round()}°",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(),

          // 4. Windstärke
          _SmallWeatherInfo(
            icon: Icons.air,
            value: "${item.windSpeed?.toStringAsFixed(1) ?? '0'} m/s",
          ),

          const SizedBox(width: 12),

          // 5. Niederschlag (Menge)
          _SmallWeatherInfo(
            icon: Icons.grain,
            value: "${item.precipitation?.toStringAsFixed(1) ?? '0'} mm",
          ),
        ],
      ),
    );
  }
}

/// Hilfs-Widget für die kleinen Info-Icons in der Kachel
class _SmallWeatherInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallWeatherInfo({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}