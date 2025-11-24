/// Repräsentiert eine Momentaufnahme der Live-Daten,
/// wie sie von der Backend-API zurückgegeben werden.
///
/// Dieses DTO (Data Transfer Object) dient als stark typisierte
/// Hülle um das JSON, das z.B. von `/actual/live-data` kommt.
class LiveDataDto {
  /// Aktuelle Temperatur in Grad Celsius.
  final double temperature;

  /// Aktuelle Luftfeuchtigkeit in Prozent.
  final double humidity;

  /// Aktueller Wasserstand (Einheit abhängig von der API,
  /// z.B. Meter oder Zentimeter).
  final double waterLevel;

  /// Erstellt ein neues [LiveDataDto] mit allen erforderlichen Werten.
  LiveDataDto({
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
  });

  /// Baut ein [LiveDataDto] aus einer JSON-Map, wie sie von der API kommt.
  ///
  /// Erwartet, dass [json] die Keys `temperature`, `humidity`
  /// und `water_level` enthält. Zahlenwerte werden sicher zu [double]
  /// gecastet.
  factory LiveDataDto.fromJson(Map<String, dynamic> json) {
    return LiveDataDto(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      waterLevel: (json['water_level'] as num).toDouble(),
    );
  }
}