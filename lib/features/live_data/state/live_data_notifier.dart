/// Repräsentiert den aktuellen Zustand des Live-Data-Features.
///
/// Dieser State enthält drei mögliche Informationen:
/// * [isLoading] – ob gerade ein API-Aufruf läuft.
/// * [errorMessage] – ein Text, falls beim Laden ein Fehler auftritt.
/// * [data] – das erfolgreich geladene [LiveDataDto]-Objekt.
///
/// Die UI liest lediglich diesen Zustand aus und entscheidet,
/// was dargestellt werden soll (Ladeanimation, Fehlermeldung, Datenanzeige).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_data_repository.dart';
import '../data/models/live_data_dto.dart';
import '../data/models/forecast_dto.dart';

class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final LiveDataDto? data;
  final List<ForecastDto>? forecast; //Liste für Zukunftsdaten

  /// Erstellt einen neuen Zustand für "Live Data".
  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
    this.forecast,
  });

  /// Hilfsmethode zum Aktualisieren nur einzelner Werte des States,
  /// ohne den gesamten Zustand manuell neu zu bauen.
  LiveDataState copyWith({
    bool? isLoading,
    String? errorMessage,
    LiveDataDto? data,
    List<ForecastDto>? forecast,
  }) {
    return LiveDataState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
      forecast: forecast ?? this.forecast,
    );
  }
}

/// StateNotifier für das Live-Data-Feature.
///
/// Diese Klasse enthält die Geschäftslogik für das Laden der Live-Daten.
/// Sie ist dafür verantwortlich:
/// * den Ladezustand zu setzen,
/// * das Repository aufzurufen,
/// * Fehler abzufangen,
/// * den State zu aktualisieren.
///
/// Die UI interagiert nie direkt mit dem Repository,
/// sondern benutzt ausschließlich die Methoden dieses Notifiers.
class LiveDataNotifier extends StateNotifier<LiveDataState> {
  final LiveDataRepository _repository;

  /// Erstellt einen neuen Notifier mit einem injizierten Repository.
  LiveDataNotifier(this._repository) : super(const LiveDataState());

  /// Lädt die aktuellen Live-Daten vom Backend.
  ///
  /// Ablauf:
  /// 1. Setzt [isLoading] auf `true`.
  /// 2. Ruft das Repository auf, um die Daten abzuholen.
  /// 3. Bei Erfolg: speichert das [LiveDataDto].
  /// 4. Bei Fehlern: speichert die Fehlermeldung im State.
  /// Lädt alle Daten (Live + Forecast) neu.
  Future<void> load() async {
    // 1. Ladezustand setzen
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 2. Parallel beide Anfragen ans Backend schicken
      //    Das ist schneller, als nacheinander zu warten.
      final results = await Future.wait([
        _repository.getLiveData(),
        _repository.getForecasts(),
      ]);

      // 3. Ergebnisse aus der Liste holen
      final liveData = results[0] as LiveDataDto;
      final forecastData = results[1] as List<ForecastDto>;

      // 4. Erfolgreichen State setzen
      state = LiveDataState(
        isLoading: false,
        data: liveData,
        forecast: forecastData, // <--- NEU: Daten speichern
      );
    } catch (e) {
      // 5. Fehler abfangen
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}