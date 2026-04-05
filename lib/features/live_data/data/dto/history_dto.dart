import 'dart:io';

class HistoryDto {
  final DateTime date;
  final double value;

  const HistoryDto({
    required this.date,
    required this.value,
  });

  factory HistoryDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final rawValue = json['value'];

    DateTime parsedDate;
    try {
      parsedDate = HttpDate.parse(rawDate.toString()).toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return HistoryDto(
      date: parsedDate,
      value: (rawValue as num).toDouble(),
    );
  }
}