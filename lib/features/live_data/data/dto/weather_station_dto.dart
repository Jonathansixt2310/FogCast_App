import 'dart:io';
class WeatherStationDto {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double waterTemperature;

  WeatherStationDto({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.waterTemperature,
  });

  factory WeatherStationDto.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final timeStr = json['time']?.toString();
      if (timeStr != null) {
        // HttpDate kann "Mon, 13 Apr 2026..." korrekt verarbeiten
        parsedDate = HttpDate.parse(timeStr).toLocal();
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      // Fallback auf ISO-Parsing, falls das Format doch variiert
      parsedDate = DateTime.tryParse(json['time'].toString()) ?? DateTime.now();
    }

    return WeatherStationDto(
      timestamp: parsedDate,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      waterTemperature: (json['water_temperature'] as num?)?.toDouble() ?? 0.0,
    );
  }
}