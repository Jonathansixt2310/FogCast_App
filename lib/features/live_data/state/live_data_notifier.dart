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

class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final LiveDataDto? data;

  /// Erstellt einen neuen Zustand für "Live Data".
  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  /// Hilfsmethode zum Aktualisieren nur einzelner Werte des States,
  /// ohne den gesamten Zustand manuell neu zu bauen.
  LiveDataState copyWith({
    bool? isLoading,
    String? errorMessage,
    LiveDataDto? data,
  }) {
    return LiveDataState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
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
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.getLiveData();
      state = LiveDataState(data: result, isLoading: false);
    } catch (e) {
      state = LiveDataState(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}