/// Riverpod-Provider für das Live-Data-Feature.
///
/// Architektur:
/// UI → Notifier → Repository → API
///
/// Diese Datei definiert alle Abhängigkeiten (Dependency Injection)
/// für Live-Daten UND Forecast-Daten.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/core/config/environment.dart';
import '../data/api/live_data_api.dart';
import '../data/repositories/live_data_repository.dart';
import '../data/api/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/repositories/forecast_repository.dart';
import 'live_data_notifier.dart';
import '../data/api/history_api.dart';
import '../data/repositories/history_repository.dart';

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
    // Nutze hier die zentrale Variable:
    modelId: Environment.defaultWeatherModel,
  );
});
/// ------------------------------
/// HISTORY / ARCHIVE
/// ------------------------------

final historyApiProvider = Provider<HistoryApi>((ref) {
  return HistoryApi();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  return HistoryRepository(api);
});