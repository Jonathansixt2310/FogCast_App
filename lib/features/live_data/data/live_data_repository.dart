import 'models/live_data_dto.dart';
import 'live_data_api.dart';

class LiveDataRepository {
  final LiveDataApi _api;

  LiveDataRepository(this._api);

  Future<LiveDataDto> getLiveData() async {
    final json = await _api.fetchLiveData();
    return LiveDataDto.fromJson(json);
  }
}