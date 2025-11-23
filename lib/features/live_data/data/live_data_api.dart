import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/environment.dart';

class LiveDataApi {
  final http.Client _client;

  LiveDataApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> fetchLiveData() async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/actual/live-data');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load live data (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}