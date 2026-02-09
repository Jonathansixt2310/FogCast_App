import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

class ForecastApi {
  final http.Client _client;

  ForecastApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<dynamic>> fetchCurrentForecast({
    required String modelId,
  }) async {
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/current-forecast',
    ).replace(queryParameters: {
      'model_id': modelId, // <-- STRING, z.B. "icon_d2"
    });

    print('FORECAST URL: $uri');

    final response = await _client.get(uri);

    print('FORECAST STATUS: ${response.statusCode}');
    print('FORECAST RESPONSE: ${response.body}');


    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load current forecast (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected forecast response (expected List)');
    }
    return decoded;
  }
}