import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';

class expert_page extends ConsumerStatefulWidget {
  const expert_page({super.key});

  @override
  ConsumerState<expert_page> createState() => _ExpertPageState();
}

class _ExpertPageState extends ConsumerState<expert_page> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(liveDataNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);

    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const tileDark = Color(0xFF4F7876);
    const chartBg = Color(0xFF274847);
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

              final now = DateTime.now();
              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));

              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(12)
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top: 4 KPI-Kacheln ---
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.speed,
                            value: data.windGust != null
                                ? data.windGust!.toStringAsFixed(1)
                                : '--',
                            unit: 'km/h',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.compress,
                            value: data.airPressure.toStringAsFixed(0),
                            unit: 'hPa',
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
                            icon: Icons.explore,
                            value: data.windDirection.toStringAsFixed(0),
                            unit: '°',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- Hourly Forecast: Windgeschwindigkeit + Richtung ---
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _ExpertHourForecastTile(
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

                    // --- Platzhalter für Experten-Grafen ---
                    _RoundedTile(
                      color: tile,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Experten-Grafen',
                              style: TextStyle(
                                color: white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 260,
                              decoration: BoxDecoration(
                                color: chartBg,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Text(
                                  'Hier kommen später die Grafen\npro ausgewähltem Feature rein',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _PrimaryPillButton(
                              text: 'Aktualisieren',
                              onPressed: () =>
                                  ref.read(liveDataNotifierProvider.notifier).load(),
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

/// ---------- UI Bausteine ----------

class _RoundedTile extends StatelessWidget {
  final Widget child;
  final Color color;

  const _RoundedTile({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: white, size: 22),
          const SizedBox(height: 8),
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

class _ExpertHourForecastTile extends StatelessWidget {
  final Color color;
  final ForecastDto dto;

  const _ExpertHourForecastTile({
    required this.color,
    required this.dto,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final hour = dto.date.hour;

    final windSpeed = dto.windSpeed ?? 0.0;
    final direction = dto.windDirection ?? 0.0;

    return Container(
      width: (MediaQuery.of(context).size.width - 36 - 36) / 4,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Uhrzeit
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          // Pfeil (Windrichtung)
          Transform.rotate(
            angle: direction * 3.1415926535897932 / 180,
            child: const Icon(
              Icons.navigation,
              color: white,
              size: 26,
            ),
          ),

          const SizedBox(height: 10),

          // Wert
          Text(
            windSpeed.toStringAsFixed(0),
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 2),

          // Einheit
          const Text(
            'km/h',
            style: TextStyle(
              color: white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
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