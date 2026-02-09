/// Riverpod-Provider für das Live-Data-Feature.
///
/// Architektur:
/// UI → Notifier → Repository → API
///
/// Diese Datei definiert alle Abhängigkeiten (Dependency Injection)
/// für Live-Daten UND Forecast-Daten.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_data_api.dart';
import '../data/live_data_repository.dart';
import '../data/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/models/forecast_repository.dart';
import 'live_data_notifier.dart';

/// ------------------------------
/// LIVE DATA
/// ------------------------------

/// API für aktuelle Messwerte (/actual/live-data)
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

/// Repository für Live-Daten
final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});

/// ------------------------------
/// FORECAST (Stunden-Vorhersage)
/// ------------------------------

/// API für Forecast (/current-forecast)
final forecastApiProvider = Provider<ForecastApi>((ref) {
  return ForecastApi();
});

/// Repository für Forecast-Daten
final forecastRepositoryProvider = Provider<ForecastRepository>((ref) {
  final api = ref.watch(forecastApiProvider);
  return ForecastRepository(api);
});

/// ------------------------------
/// NOTIFIER
/// ------------------------------

/// StateNotifier, der Live-Daten UND Forecast lädt
final liveDataNotifierProvider =
StateNotifierProvider<LiveDataNotifier, LiveDataState>((ref) {
  final liveRepo = ref.watch(liveDataRepositoryProvider);
  final forecastRepo = ref.watch(forecastRepositoryProvider);

  return LiveDataNotifier(
    liveRepo,
    forecastRepo,
    modelId: '1', // später konfigurierbar
  );
});