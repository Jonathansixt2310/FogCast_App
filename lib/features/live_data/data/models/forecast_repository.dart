import 'package:fog_cast_app/features/live_data/data/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/models/forecast_dto.dart';


class ForecastRepository {
  final ForecastApi _api;

  ForecastRepository(this._api);

  Future<List<ForecastDto>> getForecasts({required String modelId}) async {
    final raw = await _api.fetchCurrentForecast(modelId: modelId);

    return raw
        .map((e) => ForecastDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}