// lib/services/plot_engine.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'math_engine.dart';

class PlotEngine {
  final MathEngine mathEngine;
  PlotEngine(this.mathEngine);

  /// Generate plot data (list of [FlSpot]) by calling [mathEngine.evaluate()]
  /// at evenly spaced x-values between [start] and [end].
  Future<List<FlSpot>> generatePlotData(
    String function, {
    double start = -10,
    double end = 10,
    int points = 200,
  }) async {
    final spots = <FlSpot>[];

    final step = (end - start) / points;

    // Evaluate the expression at [points + 1] positions (including endpoints).
    for (int i = 0; i <= points; i++) {
      final xVal = start + (i * step);

      // Evaluate with mathEngine, providing xVal in the scope
      final evalResult = await mathEngine.evaluate(function, scope: {'x': xVal});

      // If it evaluated successfully to a numeric value, add to the plot
      if (evalResult.success && evalResult.result is num) {
        spots.add(FlSpot(xVal, (evalResult.result as num).toDouble()));
      }
      // Otherwise, ignore or handle differently
    }

    return spots;
  }

  /// Create a widget that displays a line chart of the given [function].
  Widget createPlot(
    String function, {
    double width = 300,
    double height = 200,
    double start = -10,
    double end = 10,
    int points = 200,
  }) {
    // Use a FutureBuilder so that data is generated async, and we show progress or error states.
    return FutureBuilder<List<FlSpot>>(
      future: generatePlotData(
        function,
        start: start,
        end: end,
        points: points,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            width: width,
            height: height,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final plotData = snapshot.data ?? [];

        return SizedBox(
          width: width,
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: plotData,
                  isCurved: true,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
