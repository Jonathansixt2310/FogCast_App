/// Repräsentiert den aktuellen Zustand des Live-Data-Features.
///
/// Dieser State enthält:
/// * [isLoading] – ob gerade ein API-Aufruf läuft.
/// * [errorMessage] – Text, falls beim Laden ein Fehler auftritt.
/// * [data] – geladenes [LiveDataDto]-Objekt (aktuelle Messwerte).
/// * [forecast] – Liste von [ForecastDto] (Stunden-Vorhersage).
///
/// Die UI liest nur diesen Zustand und entscheidet,
/// was dargestellt wird.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/live_data_repository.dart';
import 'package:fog_cast_app/features/live_data/data/models/forecast_repository.dart';
import '../data/models/live_data_dto.dart';
import '../data/models/forecast_dto.dart';

class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final LiveDataDto? data;
  final List<ForecastDto>? forecast;

  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
    this.forecast,
  });

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

class LiveDataNotifier extends StateNotifier<LiveDataState> {
  final LiveDataRepository _repository;
  final ForecastRepository _forecastRepository;

  /// modelId erstmal fix (später konfigurierbar über UI)
  final String _modelId;

  LiveDataNotifier(
      this._repository,
      this._forecastRepository, {
        String modelId = 'icon_d2',
      })  : _modelId = modelId,
        super(const LiveDataState());

  /// Lädt Live-Daten + Stunden-Vorhersage neu.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // parallel: live + forecast (schneller)
      final results = await Future.wait([
        _repository.getLiveData(),
        _forecastRepository.getForecasts(modelId: _modelId),
      ]);

      final liveData = results[0] as LiveDataDto;
      final forecastData = results[1] as List<ForecastDto>;

      state = LiveDataState(
        isLoading: false,
        data: liveData,
        forecast: forecastData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}