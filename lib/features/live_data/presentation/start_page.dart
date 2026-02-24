import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';
import '../data/models/forecast_dto.dart';

class start_page extends ConsumerStatefulWidget {
  const start_page({super.key});

  @override
  ConsumerState<start_page> createState() => DashboardPageState();
}

class DashboardPageState extends ConsumerState<start_page> {
  @override
  void initState() {
    super.initState();
    // lädt beim Öffnen (wie bei Joni)
    Future.microtask(() => ref.read(liveDataNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);

    // Farben wie im Figma (ungefähr)
    const bg = Color(0xFF2B4544); // dunkles Grün/Teal
    const tile = Color(0xFF5E8886); // Kachel-Farbe
    const tileDark = Color(0xFF4F7876); // etwas dunkler
    const white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FOGCAST',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Builder(
            builder: (_) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (state.errorMessage != null) {
                return Center(
                  child: _RoundedTile(
                    color: tile,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fehler:\n${state.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: white),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryPillButton(
                          text: 'Erneut laden',
                          onPressed: () =>
                              ref.read(liveDataNotifierProvider.notifier).load(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.data == null) {
                return Center(
                  child: _PrimaryPillButton(
                    text: 'Daten laden',
                    onPressed: () =>
                        ref.read(liveDataNotifierProvider.notifier).load(),
                  ),
                );
              }

              final data = state.data!;
              final forecast = state.forecast ?? <ForecastDto>[];
              debugPrint('FORECAST count: ${forecast.length}');
              if (forecast.isNotEmpty) {
                debugPrint('FORECAST first: ${forecast.first.date}');
                debugPrint('FORECAST last : ${forecast.last.date}');
              }

              final now = DateTime.now();

              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));
              // Nächste Stunden ab jetzt (egal ob Tag wechselt – viel robuster)
              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(12)
                  .toList();

              // Logik - Vorhersage nächste 7 Tage täglich min/max
              final Map<String, List<ForecastDto>> groupedByDay = {};
              for (var f in forecast) {
                final dayKey = "${f.date.year}-${f.date.month}-${f.date.day}";
                groupedByDay.putIfAbsent(dayKey, () => []).add(f);
              }
              final dayKeys = groupedByDay.keys.toList()..sort();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top: 4 KPI-Kacheln (wie Var 3) ---
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.water_drop,
                            value: '${data.humidity.toStringAsFixed(0)}',
                            unit: '%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.thermostat,
                            value: '${data.temperature.toStringAsFixed(0)}',
                            unit: '°',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.waves,
                            value: _formatWaterLevelForFigma(data.waterLevel),
                            unit: 'cm',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.air,
                            value: data.windSpeed.toStringAsFixed(1),
                            unit: 'km/h',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- Forecast: nächste Stunden (live) horizontal scrollbar ---
                    // --- Forecast: nächste Stunden (live) horizontal scrollbar ---
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 110, // gleiche Höhe wie KPI-Kacheln
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(), // oder ClampingScrollPhysics()
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _HourForecastTile(
                              color: tileDark,
                              dto: hours[i],
                            );
                          },
                        ),
                      )
                    else
                      _RoundedTile(
                        color: tileDark,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Keine Vorhersagedaten für heute verfügbar',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // --- Unten: große „7-Tage“-Kachel (Platzhalter-Design) ---
                    _RoundedTile(
                      color: tile,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            if (dayKeys.isEmpty)
                              const Text("Keine Wochendaten verfügbar", style: TextStyle(color: Colors.white))
                            else
                            // HIER DIE ÄNDERUNG: .take(7) hinzugefügt
                              ...dayKeys.take(7).map((key) {
                                final dayData = groupedByDay[key]!;
                                final date = dayData.first.date;

                                // Berechne Min/Max für diesen Tag
                                double minTempRaw = dayData.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
                                double maxTempRaw = dayData.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);

                                final String minTempFormatted = '${minTempRaw.round()}°';
                                final String maxTempFormatted = '${maxTempRaw.round()}°';

                                final label = _getWeekdayLabel(date);

                                return _DayRow(
                                  label: label,
                                  icon: _getIconForTemp(maxTempRaw),
                                  iconColor: maxTempRaw > 0 ? Colors.amber : Colors.lightBlueAccent,
                                  left: minTempFormatted,
                                  right: maxTempFormatted,
                                );
                              }).toList(),

                            const SizedBox(height: 10),
                            _PrimaryPillButton(
                              text: 'Aktualisieren',
                              onPressed: () => ref.read(liveDataNotifierProvider.notifier).load(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ---------- UI Bausteine (Kacheln) ----------

class _RoundedTile extends StatelessWidget {
  final Widget child;
  final Color color;

  const _RoundedTile({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String unit;

  const _MetricTile({
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ICON – perfekt zentriert
          Icon(icon, color: white, size: 22),

          const SizedBox(height: 8),

          // VALUE – skaliert automatisch bei großen Zahlen
          SizedBox(
            height: 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // UNIT – ebenfalls overflow-sicher
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                unit,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourForecastTile extends StatelessWidget {
  final Color color;
  final ForecastDto dto;

  const _HourForecastTile({
    required this.color,
    required this.dto,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final hour = dto.date.hour;

    final bool isNight = hour < 6 || hour > 20;
    final icon = isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;

    return Container(
      width: (MediaQuery.of(context).size.width - 36 - 36) / 4,
      height: 110, // gleiche Höhe wie KPI-Kacheln
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Zeit
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: white,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 6),

            // Icon
            Icon(icon, color: Colors.amber, size: 30),

            const SizedBox(height: 6),

            // Temperatur
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${dto.temperature.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 2),

            // Niederschlag
            SizedBox(
              height: 12,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${(dto.precipitation ?? 0).toStringAsFixed(0)}mm',
                  style: const TextStyle(
                    color: white,
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String left;
  final String right;

  const _DayRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    const textStyle = TextStyle(
      color: white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: textStyle),
          ),
          const SizedBox(width: 28),
          SizedBox(
            width: 32,
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(left, style: textStyle),
            ),
          ),
          const SizedBox(
            width: 26,
            child: Center(
              child: Text('/', style: textStyle),
            ),
          ),
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(right, style: textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryPillButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const pill = Color(0xFF2B4544);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: pill,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// ---- Helpers: Einheiten passend zu deinem Figma ----
/// Du hast im Figma bei Pegel "cm", aber dein DTO ist vermutlich in "m".
String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
}

// 7 Tage vorhersage
String _getWeekdayLabel(DateTime date) {
  final now = DateTime.now();
  if (date.day == now.day && date.month == now.month) return 'Heute';

  // Einfache Liste für deutsche Wochentage
  const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return days[date.weekday - 1];
}

IconData _getIconForTemp(double temp) {
  if (temp > 15) return Icons.wb_sunny;
  if (temp > 5) return Icons.cloud;
  return Icons.ac_unit; // Kalt/Schnee
}