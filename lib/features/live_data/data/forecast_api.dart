import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

class ForecastApi {
  final http.Client _client;

  ForecastApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<dynamic>> fetchCurrentForecast({required String modelId}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/current-forecast')
        .replace(queryParameters: {'model_id': modelId});

    final response = await _client.get(uri);

    // DEBUG (zum einmal testen)
    // ignore: avoid_print
    print('FORECAST URL: $uri');
    // ignore: avoid_print
    print('FORECAST STATUS: ${response.statusCode}');
    // ignore: avoid_print
    print('FORECAST RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load current forecast (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected forecast response (expected List)');
    }
    return decoded;
  }
}