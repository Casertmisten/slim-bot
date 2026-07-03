import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 体重折线图
class WeightChart extends StatelessWidget {
  final List<WeightRecord> records;
  const WeightChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('至少需要 2 条记录才能绘制趋势')),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), records[i].weightKg));
    }
    final weights = records.map((r) => r.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(LineChartData(
          minY: minW,
          maxY: maxW,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0x1A0B6B1D)),
            ),
          ],
        )),
      ),
    );
  }
}
