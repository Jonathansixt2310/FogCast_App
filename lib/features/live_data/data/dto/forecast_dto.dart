import 'dart:io'; // HttpDate

class ForecastDto {
  final DateTime date;

  final double temperature;
  final double? precipitation;
  final int? weatherCode;

  final double? humidity;      // relative_humidity_2m
  final double? windSpeed;     // wind_speed_10m (oder wind_speed)
  final double? windDirection;
  final double? windGust;// wind_direction_10m (optional)

  ForecastDto({
    required this.date,
    required this.temperature,
    this.precipitation,
    this.weatherCode,
    this.humidity,
    this.windSpeed,
    this.windDirection,
    this.windGust,
  });

  static double? _numOrNull(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      if (d.isNaN || !d.isFinite) return null;
      return d;
    }
    return null;
  }

  factory ForecastDto.fromApiEntry(Map<String, dynamic> json) {
    final rawDate = json['forecast_date'];
    final date = (rawDate is String && rawDate.isNotEmpty)
        ? HttpDate.parse(rawDate).toLocal()
        : DateTime.now();

    // Temperatur
    final temp = _numOrNull(json['temperature_2m']) ?? 0.0;

    // Niederschlag
    final prec = _numOrNull(json['precipitation']);

    // Wettercode
    final wcRaw = json['weather_code'];
    final wc = (wcRaw is num) ? wcRaw.toInt() : null;

    // Luftfeuchte (Forecast)
    final hum = _numOrNull(json['relative_humidity_2m']);

    // Wind (Forecast) – je nach API-Key:
    final ws = _numOrNull(json['wind_speed_10m']) ?? _numOrNull(json['wind_speed']);
    final wd = _numOrNull(json['wind_direction_10m']) ?? _numOrNull(json['wind_direction']);

    final windGust = (json['wind_gusts_10m'] is num)
        ? (json['wind_gusts_10m'] as num).toDouble()
        : null;


    return ForecastDto(
      date: date,
      temperature: temp,
      precipitation: prec,
      weatherCode: wc,
      humidity: hum,
      windSpeed: ws,
      windDirection: wd,
      windGust: windGust,
    );
  }
}