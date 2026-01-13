import 'dart:io'; // Für HttpDate

class ForecastDto {
  final DateTime date;
  final double temperature;
  final double humidity;
  final double? precipitation; // Optional, da im Log vorhanden (0.0)

  ForecastDto({
    required this.date,
    required this.temperature,
    required this.humidity,
    this.precipitation,
  });

  factory ForecastDto.fromJson(Map<String, dynamic> json) {
    // 1. Datum parsen: "Tue, 13 Jan 2026 23:00:00 GMT"
    DateTime parsedDate;
    try {
      parsedDate = HttpDate.parse(json['forecast_date'] as String);
      // Optional: Zeitverschiebung korrigieren, falls nötig (hier GMT -> Lokal)
      parsedDate = parsedDate.toLocal();
    } catch (e) {
      // Fallback, falls das Format mal abweicht
      parsedDate = DateTime.now();
    }

    return ForecastDto(
      date: parsedDate,
      // 2. Mapping der Keys aus deinem Log:
      temperature: (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toDouble(),
      precipitation: json['precipitation'] != null
          ? (json['precipitation'] as num).toDouble()
          : 0.0,
    );
  }
}