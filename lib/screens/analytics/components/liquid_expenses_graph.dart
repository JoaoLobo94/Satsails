import 'package:Satsails/helpers/asset_mapper.dart';
import 'package:Satsails/providers/analytics_provider.dart';
import 'package:Satsails/providers/currency_conversions_provider.dart';
import 'package:Satsails/providers/settings_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LineChartSample extends StatelessWidget {
  final List<int> selectedDays;
  final Map<int, num> feeData;
  final Map<int, num> incomeData;
  final Map<int, num> spendingData;
  final Map<int, num>? balanceData;
  final Map<int, num> balanceInCurrency;
  final String selectedCurrency;
  final bool showFeeLine;

  const LineChartSample({
    super.key,
    required this.selectedDays,
    required this.feeData,
    required this.incomeData,
    required this.spendingData,
    this.balanceData,
    required this.balanceInCurrency,
    required this.selectedCurrency,
    required this.showFeeLine,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      _chartData(),
    );
  }

  LineChartData _chartData() {
    final allValues = balanceData != null
        ? balanceData!.values.toList()
        : [...incomeData.values, ...spendingData.values, if (showFeeLine) ...feeData.values];
    final double minY = allValues.isNotEmpty ? allValues.reduce((a, b) => a < b ? a : b).toDouble() : 0;
    final double maxY = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b).toDouble() : 4;
    final double midY = (minY + maxY) / 2;

    final double minX = selectedDays.isNotEmpty ? selectedDays.first.toDouble() : 0;
    final double maxX = selectedDays.isNotEmpty ? selectedDays.last.toDouble() : 1;

    return LineChartData(
      lineTouchData: _lineTouchData(),
      gridData: _gridData(),
      titlesData: _titlesData(minY, midY, maxY, selectedDays.length),
      borderData: _borderData(),
      lineBarsData: balanceData != null ? [_balanceLine()] : _lineBarsData(),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  LineTouchData _lineTouchData() {
    if (balanceData == null || !showFeeLine) {
      return LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          tooltipMargin: 8,
          tooltipPadding: EdgeInsets.all(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipRoundedRadius: 8,
        ),
      );
    } else {
      return LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final FlSpot spot = touchedSpot;
              final int day = spot.x.toInt();
              final num balance = spot.y;
              final num? currencyBalance = balanceInCurrency[day];
              return LineTooltipItem(
                'Bitcoin: $balance\n$selectedCurrency: ${currencyBalance?.toStringAsFixed(2)}',
                TextStyle(color: Colors.white),
              );
            }).toList();
          },
          tooltipMargin: 8,
          tooltipPadding: EdgeInsets.all(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipRoundedRadius: 8,
        ),
      );
    }
  }

  FlTitlesData _titlesData(double minY, double midY, double maxY, int days) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: _bottomTitles(days),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false, getTitlesWidget: (value, meta) {
          const style = TextStyle(
            fontSize: 11,
            color: Colors.grey,
          );
          String text;
          if (value >= 1000) {
            text = (value / 1000).toInt().toString() + 'K';
          } else {
            text = value.toInt().toString();
          }
          return Text(text, style: style);
        }),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  List<LineChartBarData> _lineBarsData() {
    final lines = [
      _spendingLine(),
      _incomeLine(),
    ];
    if (showFeeLine) {
      lines.add(_feeLine());
    }
    return lines;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 12,
      color: Colors.grey,
    );
    String text = '';
    if (value.toInt() >= selectedDays.first && value.toInt() <= selectedDays.last) {
      text = selectedDays[(value - selectedDays.first).toInt()].toString();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: Text(text, style: style),
    );
  }

  SideTitles _bottomTitles(int days) {
    if (days > 20) {
      return SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 5,
        getTitlesWidget: _bottomTitleWidgets,
      );
    } else {
      return SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: _bottomTitleWidgets,
      );
    }
  }

  FlGridData _gridData() {
    return FlGridData(show: false);
  }

  FlBorderData _borderData() {
    return FlBorderData(
      show: false,
    );
  }

  LineChartBarData _spendingLine() {
    return LineChartBarData(
      isCurved: true,
      color: Colors.blueAccent,
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: selectedDays
          .map((day) => FlSpot(day.toDouble(), spendingData[day]?.toDouble() ?? 0))
          .toList(),
    );
  }

  LineChartBarData _incomeLine() {
    return LineChartBarData(
      isCurved: true,
      color: Colors.greenAccent,
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        color: Colors.green.withOpacity(0.3),
      ),
      spots: selectedDays
          .map((day) => FlSpot(day.toDouble(), incomeData[day]?.toDouble() ?? 0))
          .toList(),
    );
  }

  LineChartBarData _feeLine() {
    return LineChartBarData(
      isCurved: true,
      color: Colors.orangeAccent,
      barWidth: 7,
      isStrokeCapRound: false,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: selectedDays
          .map((day) => FlSpot(day.toDouble(), feeData[day]?.toDouble() ?? 0))
          .toList(),
    );
  }

  LineChartBarData _balanceLine() {
    return LineChartBarData(
      isCurved: true,
      color: Colors.orangeAccent,
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      spots: selectedDays
          .map((day) => FlSpot(day.toDouble(), balanceData?[day]?.toDouble() ?? 0))
          .toList(),
    );
  }
}

class ExpensesGraph extends ConsumerStatefulWidget {
  final String assetId;

  const ExpensesGraph({super.key, required this.assetId});

  @override
  _ExpensesGraphState createState() => _ExpensesGraphState();
}

class _ExpensesGraphState extends ConsumerState<ExpensesGraph> {
  bool isShowingBalanceData = false;

  @override
  Widget build(BuildContext context) {
    final selectedDays = ref.watch(selectedDaysDateArrayProvider);
    final feeData = ref.watch(liquidFeePerDayProvider(widget.assetId));
    final incomeData = ref.watch(liquidIncomePerDayProvider(widget.assetId));
    final spendingData = ref.watch(liquidSpentPerDayProvider(widget.assetId));
    final balanceData = ref.watch(liquidBalanceOverPeriodByDayProvider(widget.assetId));

    final selectedCurrency = ref.watch(settingsProvider).currency;
    final currencyRate = ref.watch(selectedCurrencyProvider(selectedCurrency));
    final balanceInCurrency = calculateBalanceInCurrency(balanceData, currencyRate);

    // final bitcoinBalanceByDayUnformatted = ref.watch(bitcoinBalanceInBtcByDayProvider);

    final bool showFeeLine = widget.assetId == AssetMapper.reverseMapTicker(AssetId.LBTC);

    return Expanded(
      child: Column(
        children: <Widget>[
          Container(
            height: 190, // or any other fixed height
            padding: const EdgeInsets.only(right: 16, left: 6, top: 34),
            child: LineChartSample(
              selectedDays: selectedDays,
              feeData: feeData,
              incomeData: incomeData,
              spendingData: spendingData,
              balanceData: !isShowingBalanceData ? balanceData : null,
              balanceInCurrency: balanceInCurrency,
              selectedCurrency: selectedCurrency,
              showFeeLine: showFeeLine,
            ),
          ),
          Center(
            child: TextButton(
              child: Text(
                !isShowingBalanceData ? 'Show Statistics over period' : 'Show Balance Over Time',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                setState(() {
                  isShowingBalanceData = !isShowingBalanceData;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: !isShowingBalanceData
                  ? [_buildLegend('Balance Over Time', Colors.orangeAccent)]
                  : [
                _buildLegend('Spending', Colors.blueAccent),
                _buildLegend('Income', Colors.greenAccent),
                if (showFeeLine) _buildLegend('Fee', Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }

  Map<int, num> calculateBalanceInCurrency(Map<int, num>? balanceByDay, num currencyRate) {
    final Map<int, num> balanceInCurrency = {};
    balanceByDay?.forEach((day, balance) {
      balanceInCurrency[day] = (balance * currencyRate).toDouble();
    });
    return balanceInCurrency;
  }
}
