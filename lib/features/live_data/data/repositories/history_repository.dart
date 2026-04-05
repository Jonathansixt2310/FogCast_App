import '../api/history_api.dart';
import '../dto/history_dto.dart';

class HistoryRepository {
  final HistoryApi _api;

  HistoryRepository(this._api);

  Future<List<HistoryDto>> getArchiveHistory({
    required String parameter,
    required DateTime start,
    required DateTime stop,
    int stationId = 1,
    String period = 'd',
  }) async {
    final raw = await _api.fetchArchiveHistory(
      parameter: parameter,
      start: start,
      stop: stop,
      stationId: stationId,
      period: period,
    );

    return raw
        .map((e) => HistoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}