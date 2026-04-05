import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

class HistoryApi {
  final http.Client _client;

  HistoryApi({http.Client? client}) : _client = client ?? http.Client();

  String formatDate(DateTime d) {
    return d.toUtc().toIso8601String().split('.').first;
  }

  Future<List<dynamic>> fetchArchiveHistory({
    required String parameter,
    required DateTime start,
    required DateTime stop,
    int stationId = 1,
    String period = 'd',
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/archive/$parameter').replace(
      queryParameters: {
        'start': formatDate(start),
        'stop': formatDate(stop),
        'station_id': stationId.toString(),
        'period': period,
      },
    );

    final response = await _client.get(uri);

    print('HISTORY URL: $uri');
    print('HISTORY STATUS: ${response.statusCode}');
    print('HISTORY RESPONSE: ${response.body}');
    print(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to load archive history (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Unexpected archive response (expected List)');
    }

    return decoded;
  }
}