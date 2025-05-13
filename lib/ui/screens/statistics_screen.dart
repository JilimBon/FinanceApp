import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../blocs/category/category_cubit.dart';
import '../../blocs/category/category_state.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _selectedType = 1; // 1 - расходы, 0 - доходы

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            final transactions = state.transactions;
            final filtered = transactions.where((t) =>
              t.type == _selectedType &&
              DateTime.parse(t.date).year == _selectedMonth.year &&
              DateTime.parse(t.date).month == _selectedMonth.month
            );
            final byCategory = <String, double>{};
            for (var t in filtered) {
              byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
            }
            final months = List.generate(12, (i) => DateTime(_selectedMonth.year, i + 1));
            final byMonth = List.generate(12, (i) {
              final m = i + 1;
              return transactions.where((t) =>
                t.type == _selectedType &&
                DateTime.parse(t.date).year == _selectedMonth.year &&
                DateTime.parse(t.date).month == m)
                .fold<double>(0, (sum, t) => sum + t.amount);
            });
            final maxY = ((byMonth.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1000, 100000)).toDouble();
            final interval = 5000.0;
            final expenseColors = [
              Colors.red, Colors.pink, Colors.purple, Colors.deepOrange, Colors.indigo
            ];
            final incomeColors = [
              Colors.green, Colors.lightGreen, Colors.teal, Colors.blue, Colors.cyan
            ];
            final palette = _selectedType == 1 ? expenseColors : incomeColors;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Расходы'),
                        selected: _selectedType == 1,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = 1);
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Доходы'),
                        selected: _selectedType == 0,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = 0);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _selectedType == 1 ? 'Расходы по категориям' : 'Доходы по категориям',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: byCategory.isEmpty
                        ? const Center(child: Text('Нет данных'))
                        : PieChart(
                      PieChartData(
                        sections: byCategory.entries.map((e) {
                          final color = palette[byCategory.keys.toList().indexOf(e.key) % palette.length];
                          return PieChartSectionData(
                            color: color,
                            value: e.value,
                            title: '',
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (byCategory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: byCategory.entries.map((e) {
                        final color = palette[byCategory.keys.toList().indexOf(e.key) % palette.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 16))),
                              Text('${e.value.toStringAsFixed(2)} ₽', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      _selectedType == 1 ? 'Расходы по месяцам' : 'Доходы по месяцам',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} ₽',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox(width: 48, child: Text('0', maxLines: 1, overflow: TextOverflow.ellipsis));
                                if (value % 5000 != 0) return const SizedBox.shrink();
                                return SizedBox(
                                  width: 48,
                                  child: Text(
                                    value.toInt().toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx > 11) return const SizedBox();
                                return Transform.rotate(
                                  angle: -0.5, // Поворот на 30 градусов
                                  child: SizedBox(
                                    width: 40,
                                    child: Text(
                                      DateFormat.MMM('ru').format(months[idx]),
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.black26),
                            left: BorderSide(color: Colors.black26),
                          ),
                        ),
                        barGroups: List.generate(12, (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: byMonth[i],
                              color: Theme.of(context).colorScheme.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Нет данных'));
        },
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }
}