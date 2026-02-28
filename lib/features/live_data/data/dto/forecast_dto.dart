import 'dart:io'; // Für HttpDate

class ForecastDto {
  final DateTime date;
  final double temperature;
  final double? precipitation;
  final int? weatherCode;

  ForecastDto({
    required this.date,
    required this.temperature,
    this.precipitation,
    this.weatherCode,
  });

  factory ForecastDto.fromApiEntry(Map<String, dynamic> json) {
    // forecast_date kann null sein -> fallback
    final rawDate = json['forecast_date'];
    final date = (rawDate is String && rawDate.isNotEmpty)
        ? HttpDate.parse(rawDate).toLocal()
        : DateTime.now();

    // temperature_2m kann fehlen/null sein -> fallback 0
    final tempRaw = json['temperature_2m'];
    final temp = (tempRaw is num) ? tempRaw.toDouble() : 0.0;

    final precRaw = json['precipitation'];
    final prec = (precRaw is num) ? precRaw.toDouble() : null;

    final wcRaw = json['weather_code'];
    final wc = (wcRaw is num) ? wcRaw.toInt() : null;

    return ForecastDto(
      date: date,
      temperature: temp,
      precipitation: prec,
      weatherCode: wc,
    );
  }
}