/// Riverpod-Provider für das Live-Data-Feature.
///
/// Diese Datei definiert alle Abhängigkeiten (Dependency Injection),
/// die für die Datenabfrage und den Statefluss benötigt werden.
///
/// Architektur:
/// UI → Notifier → Repository → API
///
/// Jeder Provider baut eine klar abgegrenzte Ebene:
/// * [liveDataApiProvider] – erstellt die API-Klasse für HTTP-Requests.
/// * [liveDataRepositoryProvider] – verbindet API und Datenmodell.
/// * [liveDataNotifierProvider] – stellt den State und die Business-Logik bereit.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_data_api.dart';
import '../data/live_data_repository.dart';
import 'live_data_notifier.dart';

/// Stellt eine Instanz von [LiveDataApi] bereit.
/// Diese Ebene kommuniziert direkt mit dem Backend und führt HTTP-Anfragen aus.
/// Durch Riverpod wird die Instanz sauber verwaltet und kann leicht ersetzt oder
/// gemockt werden (z. B. für Tests).
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

/// Stellt das Repository für Live Data bereit.

/// Das Repository kapselt die Datenverarbeitung:
/// * Holt JSON über die API
/// * Wandelt JSON in typisierte Modelle um
/// Die UI hat niemals direkten Kontakt zur
/// API.
final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});


///Stellt den StateNotifier bereit, der die gesamte
/// Business-Logik und den Zustand (State) des Features enthält.
/// Die UI beobachtet diesen Provider: ref.watch(liveDataNotifierProvider)
/// Und interagiert mit ihm über:
/// ref.read(liveDataNotifierProvider.notifier).load();
final liveDataNotifierProvider =
StateNotifierProvider<LiveDataNotifier, LiveDataState>((ref) {
  final repo = ref.watch(liveDataRepositoryProvider);
  return LiveDataNotifier(repo);
});