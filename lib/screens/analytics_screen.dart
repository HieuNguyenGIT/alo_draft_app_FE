import 'package:alo_draft_app/blocs/analytics/analytics_bloc.dart';
import 'package:alo_draft_app/blocs/analytics/analytics_event.dart';
import 'package:alo_draft_app/blocs/analytics/analytics_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsBloc _analyticsBloc;
  final int _selectedBarChartView = 0; // 0: grouped, 1: stacked

  // Visibility toggles for bar chart categories - now mutable
  bool _showNhanDienSo = true;
  bool _showPopup = true;
  bool _showNguonKhac = true;

  // Visibility toggles for line chart categories
  bool _showLuotTruyCap = true;
  bool _showLuotLienHe = true;

  @override
  void initState() {
    super.initState();
    _analyticsBloc = AnalyticsBloc();
    _analyticsBloc.add(AnalyticsDataLoaded());
  }

  @override
  void dispose() {
    _analyticsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _analyticsBloc,
      child: Scaffold(
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is AnalyticsLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Bar Chart Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Truy cập theo phân khúc',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Dựa trên số lượt các phân khúc khác nhau được thu thập',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: _buildBarChart(),
                            ),
                            const SizedBox(height: 16),
                            // Moved tappable legend to bottom and centered
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildTappableLegendItem(
                                      'Nhận diện số',
                                      Colors.orange,
                                      _showNhanDienSo,
                                      () => setState(() =>
                                          _showNhanDienSo = !_showNhanDienSo)),
                                  _buildTappableLegendItem(
                                      'Popup báo giá',
                                      Colors.green,
                                      _showPopup,
                                      () => setState(
                                          () => _showPopup = !_showPopup)),
                                  _buildTappableLegendItem(
                                      'Các nguồn khác',
                                      Colors.blue,
                                      _showNguonKhac,
                                      () => setState(() =>
                                          _showNguonKhac = !_showNguonKhac)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Line Chart Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lượt truy cập, liên hệ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tổng hợp số liệu thu thập được từ website alodraft-test.vn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: _buildLineChart(),
                            ),
                            const SizedBox(height: 16),
                            // Moved tappable legend to bottom and centered
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildTappableLegendItem(
                                      'Lượt truy cập',
                                      Colors.orange,
                                      _showLuotTruyCap,
                                      () => setState(() {
                                            _showLuotTruyCap =
                                                !_showLuotTruyCap;
                                          })),
                                  _buildTappableLegendItem(
                                      'Lượt liên hệ',
                                      Colors.blue,
                                      _showLuotLienHe,
                                      () => setState(() =>
                                          _showLuotLienHe = !_showLuotLienHe)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is AnalyticsFailure) {
              return Center(
                child: Text('Error: ${state.error}'),
              );
            }
            return const Center(
              child: Text('No analytics data available'),
            );
          },
        ),
      ),
    );
  }

  // New tappable legend item widget
  Widget _buildTappableLegendItem(
      String label, Color color, bool isVisible, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isVisible ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVisible ? color : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isVisible ? color : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isVisible ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        groupsSpace: _selectedBarChartView == 0 ? 12 : 20,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String category = 'Day ${16 + groupIndex}';
              String type = '';
              switch (rodIndex) {
                case 0:
                  type = 'Nhận diện số';
                  break;
                case 1:
                  type = 'Popup báo giá';
                  break;
                case 2:
                  type = 'Các nguồn khác';
                  break;
              }
              return BarTooltipItem(
                '$category\n$type: ${rod.toY.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['16', '17', '18', '19', '20', '21', '22'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
              interval: 25,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          checkToShowHorizontalLine: (value) => value % 25 == 0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        barGroups: _getBarGroupsData(),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroupsData() {
    // Mock data for the last 7 days - 3 categories per day
    final List<Map<String, double>> weekData = [
      {'nhan_dien_so': 72, 'popup': 22, 'nguon_khac': 3}, // Day 16
      {'nhan_dien_so': 80, 'popup': 25, 'nguon_khac': 5}, // Day 17
      {'nhan_dien_so': 65, 'popup': 18, 'nguon_khac': 2}, // Day 18
      {'nhan_dien_so': 55, 'popup': 22, 'nguon_khac': 4}, // Day 19
      {'nhan_dien_so': 62, 'popup': 18, 'nguon_khac': 3}, // Day 20
      {'nhan_dien_so': 72, 'popup': 8, 'nguon_khac': 6}, // Day 21
      {'nhan_dien_so': 68, 'popup': 15, 'nguon_khac': 4}, // Day 22
    ];

    return weekData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      if (_selectedBarChartView == 0) {
        // Grouped bars
        List<BarChartRodData> barRods = [];

        if (_showNhanDienSo) {
          barRods.add(BarChartRodData(
            toY: data['nhan_dien_so']!,
            color: Colors.orange,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ));
        }

        if (_showPopup) {
          barRods.add(BarChartRodData(
            toY: data['popup']!,
            color: Colors.green,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ));
        }

        if (_showNguonKhac) {
          barRods.add(BarChartRodData(
            toY: data['nguon_khac']!,
            color: Colors.blue,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ));
        }

        return BarChartGroupData(
          x: index,
          barRods: barRods,
          barsSpace: 2,
        );
      } else {
        // Stacked bars
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data['nhan_dien_so']! + data['popup']! + data['nguon_khac']!,
              color: Colors.orange,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              rodStackItems: [
                BarChartRodStackItem(0, data['nhan_dien_so']!, Colors.orange),
                BarChartRodStackItem(data['nhan_dien_so']!,
                    data['nhan_dien_so']! + data['popup']!, Colors.green),
                BarChartRodStackItem(
                    data['nhan_dien_so']! + data['popup']!,
                    data['nhan_dien_so']! +
                        data['popup']! +
                        data['nguon_khac']!,
                    Colors.blue),
              ],
            ),
          ],
        );
      }
    }).toList();
  }

  Widget _buildLineChart() {
    // Show only line chart when only "Lượt truy cập" is visible
    if (_showLuotTruyCap && !_showLuotLienHe) {
      return LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 70,
          maxY: 110,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 10,
            checkToShowHorizontalLine: (value) => value % 10 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          titlesData: _getLineChartTitles(),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _getAccessLineData(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  return LineTooltipItem(
                    'Truy cập: ${touchedSpot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      );
    }

    // Show only bar chart when only "Lượt liên hệ" is visible
    if (!_showLuotTruyCap && _showLuotLienHe) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 25,
          minY: 0,
          groupsSpace: 20,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Day ${16 + groupIndex}\nLiên hệ: ${rod.toY.round()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: _getLineChartTitles(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            checkToShowHorizontalLine: (value) => value % 5 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          barGroups: _getContactBarData(),
        ),
      );
    }

    // Show nothing if both are disabled
    if (!_showLuotTruyCap && !_showLuotLienHe) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Không có dữ liệu để hiển thị',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Combined chart (default) - Line chart with bar chart overlay
    return Stack(
      children: [
        // Line chart background
        if (_showLuotTruyCap)
          LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: 110,
              gridData: FlGridData(
                show: true,
                horizontalInterval: 20,
                checkToShowHorizontalLine: (value) => value % 20 == 0,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              titlesData: _getLineChartTitles(),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _getAccessLineData(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.orange,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.orange,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(enabled: false),
            ),
          ),
        // Bar chart overlay for contacts
        if (_showLuotLienHe)
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 110,
              minY: 0,
              groupsSpace: 20,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'Day ${16 + groupIndex}\nLiên hệ: ${rod.toY.round()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: _getContactBarData(),
            ),
          ),
      ],
    );
  }

  FlTitlesData _getLineChartTitles() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const days = ['16', '17', '18', '19', '20', '21', '22'];
            if (value.toInt() >= 0 && value.toInt() < days.length) {
              return Text(
                days[value.toInt()],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
          reservedSize: 40,
          interval: (!_showLuotTruyCap && _showLuotLienHe)
              ? 5
              : (_showLuotTruyCap && !_showLuotLienHe ? 10 : 20),
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  List<BarChartGroupData> _getContactBarData() {
    // Contact data for bars (blue bars)
    final List<double> contactData = [16, 8, 22, 18, 15, 10, 17];

    return contactData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.blue.withOpacity(0.8),
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  List<FlSpot> _getAccessLineData() {
    // Mock data for access (orange line) - matching the curve pattern in your image
    return const [
      FlSpot(0, 88),
      FlSpot(1, 82),
      FlSpot(2, 100),
      FlSpot(3, 98),
      FlSpot(4, 95),
      FlSpot(5, 84),
      FlSpot(6, 90),
    ];
  }
}
