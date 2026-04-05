import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/features/live_data/data/dto/history_dto.dart';
import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class expert_page extends ConsumerStatefulWidget {
  const expert_page({super.key});

  @override
  ConsumerState<expert_page> createState() => _ExpertPageState();
}

class _ExpertPageState extends ConsumerState<expert_page> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool temperatur = true;
  bool luftfeuchtigkeit = true;
  bool niederschlag = true;
  bool wolkendichte = false;
  bool gewitter = false;
  bool wasserlevel = true;
  List<HistoryDto> waterLevelHistory = [];
  bool isLoadingHistory = false;

  String selectedModel = 'icon_d2';
  String selectedPage = 'Standard';
  Future<void> loadWaterLevelHistory() async {
    setState(() => isLoadingHistory = true);

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 31));

    try {
      final history = await ref.read(historyRepositoryProvider).getArchiveHistory(
        parameter: 'water-level',
        start: start,
        stop: now,
        stationId: 1,
        period: 'd',
      );
      debugPrint('loaded history raw count: ${history.length}');
      if (history.isNotEmpty) {
        debugPrint('first history item: ${history.first.date} / ${history.first.value}');
      }

      setState(() {
        waterLevelHistory = history;
        isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => isLoadingHistory = false);
      debugPrint('History Fehler: $e');
    }
  }
  Future<void> _loadMenuPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      temperatur = prefs.getBool('expert_temperatur') ?? true;
      luftfeuchtigkeit = prefs.getBool('expert_luftfeuchtigkeit') ?? true;
      niederschlag = prefs.getBool('expert_niederschlag') ?? true;
      wasserlevel = prefs.getBool('expert_wasserlevel') ?? false;
      wolkendichte = prefs.getBool('expert_wolkendichte') ?? false;
      gewitter = prefs.getBool('expert_gewitter') ?? false;

      selectedModel = prefs.getString('expert_selectedModel') ?? 'icon_d2';
      selectedPage = prefs.getString('expert_selectedPage') ?? 'Standard';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setBool('temperatur', temperatur);
    prefs.setBool('luftfeuchtigkeit', luftfeuchtigkeit);
    prefs.setBool('niederschlag', niederschlag);
    prefs.setBool('wolkendichte', wolkendichte);
    prefs.setBool('gewitter', gewitter);
    prefs.setBool('wasserlevel', wasserlevel);

    prefs.setString('model', selectedModel);
    prefs.setString('page', selectedPage);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMenuPreferences();
      ref.read(liveDataNotifierProvider.notifier).load();
      await loadWaterLevelHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);
    debugPrint('wasserlevel: $wasserlevel');
    debugPrint('waterLevelHistory length: ${waterLevelHistory.length}');

    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const tileDark = Color(0xFF4F7876);
    const chartBg = Color(0xFF274847);
    const white = Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: ExpertMenuDrawer(
        temperatur: temperatur,
        luftfeuchtigkeit: luftfeuchtigkeit,
        niederschlag: niederschlag,
        wolkendichte: wolkendichte,
        gewitter: gewitter,
        wasserlevel: wasserlevel,
        selectedModel: selectedModel,
        selectedPage: selectedPage,
        onWasserlevelChanged: (v) {
          setState(() => wasserlevel = v);
          _savePreferences();
        },
        onTemperaturChanged: (v) {
          setState(() => temperatur = v);
          _savePreferences();
        },
        onLuftfeuchtigkeitChanged:  (v) {
          setState(() => luftfeuchtigkeit = v);
          _savePreferences();
        },
        onNiederschlagChanged: (v) {
          setState(() => niederschlag = v);
          _savePreferences();
        },
        onWolkendichteChanged: (v) {
          setState(() => wolkendichte = v);
          _savePreferences();
        },
        onGewitterChanged: (v) {
          setState(() => gewitter = v);
          _savePreferences();
        },
        onModelChanged: (v) {
          setState(() => selectedModel = v);
          _savePreferences();
        },
        onPageChanged: (v) {
          setState(() => selectedPage = v);
          _savePreferences();
        },

      ),      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FOGCAST',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Builder(
            builder: (_) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (state.errorMessage != null) {
                return Center(
                  child: _RoundedTile(
                    color: tile,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fehler:\n${state.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: white),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryPillButton(
                          text: 'Erneut laden',
                          onPressed: () =>
                              ref.read(liveDataNotifierProvider.notifier).load(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.data == null) {
                return Center(
                  child: _PrimaryPillButton(
                    text: 'Daten laden',
                    onPressed: () =>
                        ref.read(liveDataNotifierProvider.notifier).load(),
                  ),
                );
              }

              final data = state.data!;
              final forecast = state.forecast ?? <ForecastDto>[];

              final now = DateTime.now();
              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));

              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(12)
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.speed,
                            value: data.windGust != null
                                ? data.windGust!.toStringAsFixed(1)
                                : '--',
                            unit: 'km/h',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.compress,
                            value: data.airPressure.toStringAsFixed(0),
                            unit: 'hPa',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.waves,
                            value: _formatWaterLevelForFigma(data.waterLevel),
                            unit: 'cm',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.explore,
                            value: data.windDirection.toStringAsFixed(0),
                            unit: '°',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _ExpertHourForecastTile(
                              color: tileDark,
                              dto: hours[i],
                            );
                          },
                        ),
                      )
                    else
                      _RoundedTile(
                        color: tileDark,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Keine Vorhersagedaten für heute verfügbar',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (temperatur) ...[
                          _ExpertGraphCard(
                            title: 'Temperatur',
                            child: _ExpertLineChart(
                              data: forecast,
                              unitY: '°C',
                              unitX: 'Uhrzeit',
                              valueSelector: (f) => f.temperature,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (luftfeuchtigkeit) ...[
                          _ExpertGraphCard(
                            title: 'Luftfeuchtigkeit',
                            child: _ExpertLineChart(
                              data: forecast,
                              unitY: '%',
                              unitX: 'Uhrzeit',
                              valueSelector: (f) => f.humidity,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (niederschlag) ...[
                          _ExpertGraphCard(
                            title: 'Niederschlag',
                            child: _ExpertLineChart(
                              data: forecast,
                              unitY: 'mm',
                              unitX: 'Uhrzeit',
                              valueSelector: (f) => f.precipitation,
                              curved: false,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (wasserlevel) ...[
                          _ExpertGraphCard(
                            title: 'Wasserlevel',
                            child: _ExpertWaterLevelHistoryChart(
                              data: waterLevelHistory
                                  .map((e) => _WaterLevelPoint(
                                date: e.date,
                                valueCm: e.value,
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (wolkendichte) ...[
                          _ExpertGraphCard(
                            title: 'Wolkendichte',
                            child: _ExpertLineChart(
                              data: forecast,
                              unitY: '%',
                              unitX: 'Uhrzeit',
                              valueSelector: (f) => f.cloudCover,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (gewitter) ...[
                          _ExpertGraphCard(
                            title: 'Gewitter',
                            child: _ExpertLineChart(
                              data: forecast,
                              unitY: '',
                              unitX: 'Uhrzeit',
                              valueSelector: (f) => f.cape,
                              curved: false,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        _PrimaryPillButton(
                          text: 'Aktualisieren',
                          onPressed: () => ref.read(liveDataNotifierProvider.notifier).load(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ---------- UI Bausteine ----------

class _RoundedTile extends StatelessWidget {
  final Widget child;
  final Color color;

  const _RoundedTile({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String unit;

  const _MetricTile({
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: white, size: 22),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                unit,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertLineChart extends StatelessWidget {
  final List<ForecastDto> data;
  final String unitY;
  final String unitX;
  final double? Function(ForecastDto f) valueSelector;
  final bool curved;

  const _ExpertLineChart({
    required this.data,
    required this.unitY,
    required this.unitX,
    required this.valueSelector,
    this.curved = true,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;

    final now = DateTime.now();
    final start = now;
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dayData = data
        .where((f) => !f.date.isBefore(start) && !f.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (final f in dayData) {
      final x = f.date.hour + (f.date.minute / 60.0);
      final y = valueSelector(f);

      if (y != null && y.isFinite) {
        spots.add(FlSpot(x, y));
      }
    }

    if (spots.length < 2) {
      return const Center(
        child: Text(
          'Keine Daten verfügbar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 16,
          ),
        ),
      );
    }

    double minY = spots.first.y;
    double maxY = spots.first.y;

    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    minY = minY.floorToDouble();
    maxY = maxY.ceilToDouble();

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final minX = spots.first.x;
    final maxX = 23.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.black.withOpacity(0.55),
                  width: 1.4,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: _intervalForY(maxY - minY),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 3,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final rounded = value.round();

                      if (rounded < minX.floor() || rounded > 23) {
                        return const SizedBox.shrink();
                      }

                      return Text(
                        '${rounded.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: curved,
                  barWidth: 3.5,
                  color: white,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),

          Positioned(
            left: 4,
            top: 6,
            child: Text(
              unitY,
              style: const TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: 2,
            child: Text(
              unitX,
              style: const TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _intervalForY(double range) {
  if (range <= 5) return 1;
  if (range <= 10) return 2;
  if (range <= 20) return 5;
  if (range <= 50) return 10;
  return 20;
}

class _ExpertGraphCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ExpertGraphCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const chartBg = Color(0xFF274847);
    const white = Colors.white;

    return _RoundedTile(
      color: tile,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: chartBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertHourForecastTile extends StatelessWidget {
  final Color color;
  final ForecastDto dto;

  const _ExpertHourForecastTile({
    required this.color,
    required this.dto,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final hour = dto.date.hour;
    final windSpeed = dto.windSpeed ?? 0.0;
    final direction = dto.windDirection ?? 0.0;

    return Container(
      width: (MediaQuery.of(context).size.width - 36 - 36) / 4,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Transform.rotate(
            angle: direction * 3.1415926535897932 / 180,
            child: const Icon(
              Icons.navigation,
              color: white,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            windSpeed.toStringAsFixed(0),
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'km/h',
            style: TextStyle(
              color: white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertWaterLevelHistoryChart extends StatelessWidget {
  final List<_WaterLevelPoint> data;

  const _ExpertWaterLevelHistoryChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;

    if (data.length < 2) {
      return const Center(
        child: Text(
          'Keine historischen Wasserlevel-Daten verfügbar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 16,
          ),
        ),
      );
    }

    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = sorted
        .where((p) => !p.date.isBefore(startDate) && !p.date.isAfter(endDate))
        .toList();

    if (filtered.length < 2) {
      return const Center(
        child: Text(
          'Keine historischen Wasserlevel-Daten verfügbar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 16,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      spots.add(FlSpot(i.toDouble(), filtered[i].valueCm));
    }

    double minY = filtered.first.valueCm;
    double maxY = filtered.first.valueCm;

    for (final p in filtered) {
      if (p.valueCm < minY) minY = p.valueCm;
      if (p.valueCm > maxY) maxY = p.valueCm;
    }

    minY = minY.floorToDouble();
    maxY = maxY.ceilToDouble();

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minX: 0,
              maxX: (filtered.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.black.withOpacity(0.55),
                  width: 1.4,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _intervalForY(maxY - minY),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _xIntervalForHistory(filtered.length),
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= filtered.length) {
                        return const SizedBox.shrink();
                      }

                      final d = filtered[index].date;
                      return Text(
                        '${d.day}.${d.month}.',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3.5,
                  color: white,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),

          const Positioned(
            left: 4,
            top: 6,
            child: Text(
              'cm',
              style: TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Positioned(
            right: 8,
            bottom: 2,
            child: Text(
              'Datum',
              style: TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
}

class ExpertMenuDrawer extends StatelessWidget {
  final bool temperatur;
  final bool luftfeuchtigkeit;
  final bool niederschlag;
  final bool wolkendichte;
  final bool gewitter;
  final bool wasserlevel;

  final String selectedModel;
  final String selectedPage;

  final ValueChanged<bool> onTemperaturChanged;
  final ValueChanged<bool> onLuftfeuchtigkeitChanged;
  final ValueChanged<bool> onNiederschlagChanged;
  final ValueChanged<bool> onWolkendichteChanged;
  final ValueChanged<bool> onGewitterChanged;
  final ValueChanged<bool> onWasserlevelChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onPageChanged;

  const ExpertMenuDrawer({
    super.key,
    required this.temperatur,
    required this.luftfeuchtigkeit,
    required this.niederschlag,
    required this.wolkendichte,
    required this.gewitter,
    required this.wasserlevel,
    required this.selectedModel,
    required this.selectedPage,
    required this.onTemperaturChanged,
    required this.onLuftfeuchtigkeitChanged,
    required this.onNiederschlagChanged,
    required this.onWolkendichteChanged,
    required this.onGewitterChanged,
    required this.onWasserlevelChanged,
    required this.onModelChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FOGCAST',
                  style: TextStyle(
                    color: white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Parameterauswahl',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                _MenuCheckRow(
                  label: 'Temperatur',
                  value: temperatur,
                  onChanged: onTemperaturChanged,
                ),
                _MenuCheckRow(
                  label: 'Luftfeuchtigkeit',
                  value: luftfeuchtigkeit,
                  onChanged: onLuftfeuchtigkeitChanged,
                ),
                _MenuCheckRow(
                  label: 'Niederschlag',
                  value: niederschlag,
                  onChanged: onNiederschlagChanged,
                ),
                _MenuCheckRow(
                  label: 'Wasserlevel',
                  value: wasserlevel,
                  onChanged: onWasserlevelChanged,
                ),
                _MenuCheckRow(
                  label: 'Wolkendichte',
                  value: wolkendichte,
                  onChanged: onWolkendichteChanged,
                ),
                _MenuCheckRow(
                  label: 'Gewitter',
                  value: gewitter,
                  onChanged: onGewitterChanged,
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tile,
                      foregroundColor: white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Speichern',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Modellauswahl',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _MenuDropdown(
                  value: selectedModel,
                  items: const ['icon_d2', 'icon_eu', 'icon_global'],
                  onChanged: (v) {
                    if (v != null) {
                      onModelChanged(v);
                    }
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Deine Seiten',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _MenuDropdown(
                  value: selectedPage,
                  items: const ['Standard', 'Wind', 'Niederschlag'],
                  onChanged: (v) {
                    if (v != null) {
                      onPageChanged(v);
                    }
                  },
                ),

                const SizedBox(height: 28),

                const Icon(Icons.swap_horiz, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuCheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: value
                  ? const Icon(Icons.check, color: white, size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MenuDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: tile,
          icon: const Icon(Icons.keyboard_arrow_down, color: white),
          style: const TextStyle(
            color: white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryPillButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const pill = Color(0xFF2B4544);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: pill,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _WaterLevelPoint {
  final DateTime date;
  final double valueCm;

  const _WaterLevelPoint({
    required this.date,
    required this.valueCm,
  });
}
double _xIntervalForHistory(int count) {
  if (count <= 7) return 1;
  if (count <= 14) return 2;
  if (count <= 21) return 3;
  return 5;
}