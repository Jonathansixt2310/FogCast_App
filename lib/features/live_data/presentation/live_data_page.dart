/// Bildschirm (UI) für die Anzeige der Live-Daten.
///
/// Diese Seite beobachtet den Riverpod-State aus
/// [liveDataNotifierProvider] und reagiert dynamisch auf
/// verschiedene Zustände:
///
/// * **Ladezustand** → zeigt einen CircularProgressIndicator.
/// * **Fehlerzustand** → zeigt eine Fehlermeldung und einen Button,
///   um das Laden erneut zu starten.
/// * **Datenzustand** → zeigt Temperatur, Luftfeuchte und Wasserstand.
/// * **Initialzustand** → zeigt einen Button „Daten laden“.
///
/// Die UI enthält selbst keinerlei Logik zum Datenabruf.
/// Stattdessen ruft sie Methoden des StateNotifiers auf, z. B.:
/// `ref.read(liveDataNotifierProvider.notifier).load()`.
///
/// Dadurch bleibt die Darstellung klar von API- und Datenlogik getrennt.
/// Dies ist ideal für Wartbarkeit, Testbarkeit und eine saubere
/// Architektur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';

class LiveDataPage extends ConsumerStatefulWidget {
  const LiveDataPage({super.key});

  @override
  ConsumerState<LiveDataPage> createState() => _LiveDataPageState();
}

class _LiveDataPageState extends ConsumerState<LiveDataPage> {
  @override
  void initState() {
    super.initState();
    // Daten automatisch beim Öffnen laden
    Future.microtask(() {
      ref.read(liveDataNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);

    Widget body;

    if (state.isLoading) {
      body = const CircularProgressIndicator();
    } else if (state.errorMessage != null) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Fehler: ${state.errorMessage}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(liveDataNotifierProvider.notifier).load(),
            child: const Text('Erneut laden'),
          ),
        ],
      );
    } else if (state.data != null) {
      final data = state.data!;
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Temperatur: ${data.temperature} °C'),
          Text('Luftfeuchte: ${data.humidity} %'),
          Text('Pegel: ${data.waterLevel} m'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(liveDataNotifierProvider.notifier).load(),
            child: const Text('Aktualisieren'),
          ),
        ],
      );
    } else {
      // Sollte praktisch nicht mehr auftreten,
      // weil wir automatisch laden – bleibt als Fallback
      body = ElevatedButton(
        onPressed: () =>
            ref.read(liveDataNotifierProvider.notifier).load(),
        child: const Text('Daten laden'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live-Daten')),
      body: Center(child: body),
    );
  }
}