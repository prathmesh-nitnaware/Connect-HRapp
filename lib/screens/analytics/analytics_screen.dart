import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/advanced_analytics_model.dart';
import '../../providers/advanced_analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionService>();
      context.read<AdvancedAnalyticsProvider>().fetchAdvancedAnalytics(token: session.token);
    });
  }

  void _exportAttendance() async {
    final session = context.read<SessionService>();
    final csv = await context.read<AdvancedAnalyticsProvider>().exportAttendanceCsv(token: session.token);
    if (mounted && csv != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text('✅ Attendance CSV Exported (${csv.split('\n').length} rows)'),
        ),
      );
    }
  }

  void _exportLeaves() async {
    final session = context.read<SessionService>();
    final csv = await context.read<AdvancedAnalyticsProvider>().exportLeavesCsv(token: session.token);
    if (mounted && csv != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text('✅ Leaves CSV Exported (${csv.split('\n').length} rows)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<AdvancedAnalyticsProvider>();
    final theme = Theme.of(context);
    final data = provider.analytics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced HR Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAdvancedAnalytics(token: session.token),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Unable to load analytics data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. KPI Top Summary Cards
                      _buildKpiGrid(data, theme),
                      const SizedBox(height: 24),

                      // 2. Export Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Export Attendance CSV'),
                              onPressed: _exportAttendance,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.file_download),
                              label: const Text('Export Leaves CSV'),
                              onPressed: _exportLeaves,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. Department Headcount Bar Chart
                      Text('Department Headcount Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildDepartmentChart(data.departmentHeadcounts, theme),
                      const SizedBox(height: 24),

                      // 4. Weekly Attendance Rate Trend Line Chart
                      Text('Weekly Attendance Rate (%)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildAttendanceTrendChart(data.attendanceTrends, theme),
                      const SizedBox(height: 24),

                      // 5. Expense Breakdown Pie Chart
                      Text('Quarterly Reimbursements by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildExpensePieChart(data.expenseBreakdown, theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid(AdvancedHRAnalytics data, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: [
        _buildKpiCard('Turnover Rate', '${data.turnoverRate}%', Icons.trending_down, Colors.redAccent, theme),
        _buildKpiCard('Headcount', '${data.activeHeadcount}', Icons.groups, Colors.blueAccent, theme),
        _buildKpiCard('Avg Hours', '${data.avgMonthlyWorkHours}h', Icons.timer, Colors.green, theme),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChart(List<DepartmentHeadcount> items, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 65,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                      final dept = items[idx].department;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dept.length > 5 ? dept.substring(0, 4) : dept,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 15),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: items.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: theme.colorScheme.primary,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendChart(List<AttendanceTrendDay> items, ThemeData theme) {
    final spots = items.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.presentRate)).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 80,
              maxY: 100,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(items[idx].day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 5),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensePieChart(List<ExpenseCategoryTotal> items, ThemeData theme) {
    final colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.pink];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 160,
              width: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: items.asMap().entries.map((e) {
                    final color = colors[e.key % colors.length];
                    return PieChartSectionData(
                      value: e.value.total,
                      title: '₹${(e.value.total / 1000).toStringAsFixed(0)}k',
                      color: color,
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: items.asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value.category, style: const TextStyle(fontSize: 12))),
                        Text('₹${e.value.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
