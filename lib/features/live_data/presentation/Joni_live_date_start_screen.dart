import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';
import '../data/models/forecast_dto.dart'; // Import für den Typ ForecastDto
import 'live_data_page.dart';

class LiveDataDashboard extends ConsumerStatefulWidget {
  const LiveDataDashboard({super.key});

  @override
  ConsumerState<LiveDataDashboard> createState() => _LiveDataDashboardState();
}

class _LiveDataDashboardState extends ConsumerState<LiveDataDashboard> {
  @override
  void initState() {
    super.initState();
    // Lädt Live-Daten UND Vorhersage beim Start
    Future.microtask(() {
      ref.read(liveDataNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Beobachtet den kompletten State
    final state = ref.watch(liveDataNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FogCast Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(liveDataNotifierProvider.notifier).load(),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // 1. Ladezustand
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Fehlerzustand
          if (state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Fehler: ${state.errorMessage}'),
              ),
            );
          }

          // 3. Daten vorhanden?
          if (state.data != null) {
            final data = state.data!;
            // Holen der echten Vorhersage-Liste (oder leere Liste, falls null)
            final forecastList = state.forecast ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Aktuelle Übersicht',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // --- OBERE KACHEL (LIVE DATEN) ---
                  Card(
                    elevation: 4,
                    color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DataColumn(
                            icon: Icons.thermostat,
                            value: '${data.temperature} °C',
                            label: 'Temp.',
                            color: Colors.orange,
                          ),
                          Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.withOpacity(0.5)),
                          _DataColumn(
                            icon: Icons.water_drop,
                            value: '${data.humidity} %',
                            label: 'Feuchte',
                            color: Colors.blue,
                          ),
                          Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.withOpacity(0.5)),
                          _DataColumn(
                            icon: Icons.waves,
                            value: '${data.waterLevel} m',
                            label: 'Pegel',
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- UNTERE KACHEL (ECHTE VORHERSAGE) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vorhersage (icon_d2)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (forecastList.isEmpty)
                        Text(
                          'Keine Daten',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (forecastList.isNotEmpty)
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        // Begrenzung auf z.B. 24 Stunden, falls die Liste sehr lang ist
                        itemCount: forecastList.length > 24 ? 24 : forecastList.length,
                        separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = forecastList[index];
                          return _ForecastCard(dto: item);
                        },
                      ),
                    )
                  else
                    const SizedBox(
                      height: 100,
                      child: Center(child: Text("Keine Vorhersagedaten verfügbar")),
                    ),

                  const SizedBox(height: 32),

                  // --- BUTTON ZUR HISTORIE ---
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LiveDataPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Vollständige Historie ansehen'),
                  ),
                ],
              ),
            );
          }

          // Fallback
          return const Center(child: Text('Keine Daten.'));
        },
      ),
    );
  }
}

// --- HILFSWIDGETS ---

/// Zeigt eine einzelne Stunde der Vorhersage an.
class _ForecastCard extends StatelessWidget {
  final ForecastDto dto;

  const _ForecastCard({required this.dto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Logik für das Icon (Tag/Nacht)
    final hour = dto.date.hour;
    final isNight = hour < 6 || hour > 20;
    final icon = isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Uhrzeit formatieren (z.B. "14:00")
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Icon(icon, color: Colors.orangeAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            '${dto.temperature.toStringAsFixed(1)}°',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Zeigt eine Spalte (Icon, Wert, Label) in der Live-Daten-Karte an.
class _DataColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DataColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}