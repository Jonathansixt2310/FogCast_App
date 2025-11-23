//Dummy-code

class LiveDataDto {
  final double temperature;
  final double humidity;
  final double waterLevel;

  LiveDataDto({
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
  });

  factory LiveDataDto.fromJson(Map<String, dynamic> json) {
    return LiveDataDto(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      waterLevel: (json['water_level'] as num).toDouble(),
    );
  }
}