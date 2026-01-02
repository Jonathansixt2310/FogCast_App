/// Repository für das Feature "Live Data".
///
/// Das Repository bildet die Mittelschicht zwischen API und State.
/// Es ruft die HTTP-Endpunkte über [LiveDataApi] auf und wandelt die
/// JSON-Antworten in stark typisierte Dart-Objekte um.
///
/// Die UI und der State arbeiten ausschließlich mit [LiveDataDto],
/// nicht mit JSON-Maps. Dadurch bleiben Netzwerklayer und Datenmodell
/// klar voneinander getrennt.

import 'models/live_data_dto.dart';
import 'live_data_api.dart';

class LiveDataRepository {
  /// API-Klasse, die die HTTP-Requests ausführt.
  final LiveDataApi _api;

  /// Erstellt ein neues Repository, dem eine [LiveDataApi]
  /// übergeben wird (oft injiziert durch Riverpod).
  LiveDataRepository(this._api);

  /// Holt die aktuellen Live-Daten vom Backend.
  ///
  /// Ablauf:
  /// 1. API wird über [_api.fetchLiveData()] aufgerufen.
  /// 2. JSON wird empfangen und dekodiert.
  /// 3. JSON wird in ein [LiveDataDto] umgewandelt.
  ///
  /// Das Ergebnis ist ein typisiertes Datenobjekt, das weiter
  /// an den StateNotifier gereicht wird.
  Future<LiveDataDto> getLiveData() async {
    final raw = await _api.fetchLiveData();

    if (raw is List) {
      return LiveDataDto.fromList(raw);
    }

    throw Exception('Unexpected response format: ${raw.runtimeType}');
  }
}