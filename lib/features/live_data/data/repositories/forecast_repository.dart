import '../api/forecast_api.dart';
import '../dto/forecast_dto.dart';

class ForecastRepository {
  final ForecastApi _api;

  ForecastRepository(this._api);

  Future<List<ForecastDto>> getForecasts({
    required String modelId,
  }) async {
    final raw = await _api.fetchCurrentForecast(modelId: modelId);

    // raw ist List<dynamic> (von der API validiert), wir casten sauber:
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => ForecastDto.fromApiEntry(e))
        .toList();
  }
}