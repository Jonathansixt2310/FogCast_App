class LiveDataDto {
  final double temperature; // °C
  final double humidity; // %
  final double waterLevel; // m
  final double windSpeed; // m/s
  final double windDirection; // °
  final double airPressure; // hPa
  final double windGust; // m/s oder 0.0 falls nicht vorhanden

  LiveDataDto({
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.windSpeed,
    required this.windDirection,
    required this.airPressure,
    required this.windGust,
  });

  /// Baut ein DTO aus der API-Liste:
  /// [{"name":"temperature","value":"3.0", ...}, ...]
  factory LiveDataDto.fromList(List<dynamic> items) {
    double? temp;
    double? hum;
    double? water;
    double? windSpeed;
    double? windDirection;
    double? airPressure;
    double? windGust;

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
          hum = value * 100.0; // 0.678 -> 67.8 %
          break;
        case 'water_level':
          water = value / 100.0; // cm -> m
          break;
        case 'wind_speed':
          windSpeed = value;
          break;
        case 'wind_direction':
          windDirection = value;
          break;
        case 'air_pressure':
          airPressure = value;
          break;
        case 'wind_gust':
          windGust = value;
          break;
      }
    }

    if (temp == null ||
        hum == null ||
        water == null ||
        windSpeed == null ||
        windDirection == null ||
        airPressure == null) {
      throw Exception('LiveData unvollständig');
    }

    return LiveDataDto(
      temperature: temp,
      humidity: hum,
      waterLevel: water,
      windSpeed: windSpeed,
      windDirection: windDirection,
      airPressure: airPressure,
      windGust: windGust ?? 0.0,
    );
  }
}