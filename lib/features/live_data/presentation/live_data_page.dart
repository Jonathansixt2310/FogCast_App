import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';

class LiveDataPage extends ConsumerWidget {
  const LiveDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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