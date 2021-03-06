import 'dart:math';

import 'package:danger_zone_alert/models/state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


// This is used to display the detail of crime cases in each state after users tap on of the list of cards
class StateBarChart extends StatelessWidget {
  StateInfo state;

  StateBarChart({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<int> crimeCounts = [
      state.murder,
      state.robbery,
      state.causingInjury,
      state.rape
    ];

    return BarChart(
      BarChartData(
        titlesData: titlesData,
        borderData: borderData,
        barGroups: chartData(crimeCounts),
        gridData: FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: crimeCounts.reduce(max).toDouble() +
            crimeCounts.reduce(max).toDouble() * 0.2,
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
        color: Color(0xff7589a2), fontWeight: FontWeight.bold, fontSize: 14);
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Murder';
        break;
      case 1:
        text = 'Robbery';
        break;
      case 2:
        text = 'Causing Injury';
        break;
      case 3:
        text = 'Rape';
        break;
      default:
        text = '';
        break;
    }
    return Center(child: Text(text, style: style));
  }

  FlTitlesData get titlesData => FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: true, reservedSize: 50, getTitlesWidget: getTitles)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)));

  FlBorderData get borderData => FlBorderData(show: false);

  final _barsColor = [
    const Color(0xffc06c84),
    const Color(0xfff67280),
    const Color(0xff4b87b9),
    const Color(0xfff8b195)
  ];

  List<BarChartGroupData> chartData(crimeCounts) {
    List<BarChartGroupData> barChartData = [];

    int index = 0;
    for (int crimeCount in crimeCounts) {
      barChartData.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            width: 30.0,
            toY: crimeCount.toDouble(),
            color: _barsColor[index],
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
          ),
        ],
        showingTooltipIndicators: [0],
      ));
      index++;
    }

    return barChartData;
  }
}
