class LiveDataDto {
  final double temperature; // °C
  final double humidity;    // %
  final double waterLevel;  // m
  final double windSpeed; // m/s

  LiveDataDto({
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.windSpeed,
  });

  /// Baut ein DTO aus der API-Liste:
  /// [{"name":"temperature","value":"3.0", ...}, ...]
  factory LiveDataDto.fromList(List<dynamic> items) {
    double? temp;
    double? hum;
    double? water;
    double? windSpeed;

    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String?;
      final valueStr = map['value']?.toString();

      if (name == null || valueStr == null) continue;

      final value = double.tryParse(valueStr);
      if (value == null) continue;

      switch (name) {
        case 'temperature':
          temp = value;
          break;
        case 'humidity':
          hum = value * 100.0; // 0.678 → 67.8 %
          break;
        case 'water_level':
          water = value / 100.0; // cm → m
          break;
        case 'wind_speed':
          windSpeed = value;
          break;
      }
    }

    if (temp == null || hum == null || water == null || windSpeed == null) {
      throw Exception('LiveData unvollständig');
    }

    return LiveDataDto(
      temperature: temp,
      humidity: hum,
      waterLevel: water,
      windSpeed: windSpeed,
    );
  }
}