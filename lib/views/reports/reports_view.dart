import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/empty_state_view.dart';
import '../../components/app_colors.dart';

enum ReportPeriod {
  week('Week'),
  month('Month'),
  year('Year');

  const ReportPeriod(this.label);
  final String label;
}

class ReportsView extends StatefulWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  ReportPeriod _selectedPeriod = ReportPeriod.month;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.week:
        return now.subtract(const Duration(days: 7));
      case ReportPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
      case ReportPeriod.year:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> txs, DateTime start, DateTime end) {
    return txs.where((t) => t.date.isAfter(start) && t.date.isBefore(end)).toList();
  }

  List<_CategorySpendingItem> _getCategorySpending(List<Transaction> txs, List<Category> categories) {
    final Map<String, double> grouped = {};
    for (var txn in txs) {
      if (txn.type == TransactionType.expense) {
        grouped[txn.categoryId] = (grouped[txn.categoryId] ?? 0.0) + txn.amount;
      }
    }

    final List<_CategorySpendingItem> items = [];
    grouped.forEach((catId, amount) {
      final category = categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => const Category(id: '', name: 'Unknown', icon: '❓', color: '#888888', type: CategoryType.expense),
      );
      if (category.id != null && category.id!.isNotEmpty) {
        items.add(_CategorySpendingItem(
          categoryId: catId,
          name: category.name,
          color: category.color,
          amount: amount,
        ));
      }
    });

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  List<_IncomeExpenseItem> _getIncomeExpenseData(List<Transaction> txs) {
    final Map<String, List<Transaction>> grouped = {};
    final DateFormat formatter = _selectedPeriod == ReportPeriod.year
        ? DateFormat('yyyy-MM')
        : DateFormat('yyyy-MM-dd');

    for (var txn in txs) {
      final key = formatter.format(txn.date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    final List<_IncomeExpenseItem> result = [];
    grouped.forEach((key, list) {
      final date = formatter.parse(key);
      double income = 0.0;
      double expense = 0.0;
      for (var txn in list) {
        if (txn.type == TransactionType.income) {
          income += txn.amount;
        } else if (txn.type == TransactionType.expense) {
          expense += txn.amount;
        }
      }
      result.add(_IncomeExpenseItem(date: date, income: income, expense: expense));
    });

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  List<_BalanceTrendItem> _getNetBalanceTrend(List<Transaction> allTxs, DateTime start, DateTime end) {
    final pastTxs = allTxs.where((t) => t.date.isBefore(start)).toList();
    double currentBalance = 0.0;
    for (var txn in pastTxs) {
      if (txn.type == TransactionType.income) {
        currentBalance += txn.amount;
      } else if (txn.type == TransactionType.expense) {
        currentBalance -= txn.amount;
      }
    }

    final rangeTxs = allTxs.where((t) => t.date.isAfter(start) && t.date.isBefore(end)).toList();
    rangeTxs.sort((a, b) => a.date.compareTo(b.date));

    final List<_BalanceTrendItem> trend = [];
    trend.add(_BalanceTrendItem(date: start, balance: currentBalance));

    for (var txn in rangeTxs) {
      if (txn.type == TransactionType.income) {
        currentBalance += txn.amount;
      } else if (txn.type == TransactionType.expense) {
        currentBalance -= txn.amount;
      }
      trend.add(_BalanceTrendItem(date: txn.date, balance: currentBalance));
    }

    trend.add(_BalanceTrendItem(date: end, balance: currentBalance));
    return trend;
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;

    final end = DateTime.now();
    final start = _startDate;

    final rangeTxs = _filterTransactions(dataStore.transactions, start, end);
    final spendingItems = _getCategorySpending(rangeTxs, dataStore.categories);
    final barItems = _getIncomeExpenseData(rangeTxs);
    final trendItems = _getNetBalanceTrend(dataStore.transactions, start, end);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Reports',
          style: TextStyle(color: AppColors.label(context)),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Segmented period picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<ReportPeriod>(
                  groupValue: _selectedPeriod,
                  onValueChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPeriod = val;
                      });
                    }
                  },
                  children: Map.fromEntries(
                    ReportPeriod.values.map(
                      (p) => MapEntry(
                        p,
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(p.label),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (rangeTxs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: EmptyStateView(
                  icon: CupertinoIcons.chart_pie_fill,
                  title: 'No Data',
                  subtitle: 'There are no transactions for this period.',
                ),
              )
            else ...[
              // Donut Pie Chart Card
              if (spendingItems.isNotEmpty)
                _ChartCard(
                  title: 'Spending by Category',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: spendingItems.map((item) {
                              return PieChartSectionData(
                                color: AppColors.hexToColor(item.color),
                                value: item.amount,
                                title: '',
                                radius: 30,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Custom Legend
                      ...spendingItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.hexToColor(item.color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                '$currencySymbol${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryLabel(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // Bar Chart Card
              if (barItems.isNotEmpty)
                _ChartCard(
                  title: 'Income vs. Expense',
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: item.income,
                                color: CupertinoColors.systemGreen,
                                width: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: item.expense,
                                color: CupertinoColors.systemRed,
                                width: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final int index = val.toInt();
                                if (index < 0 || index >= barItems.length) return const SizedBox.shrink();
                                final date = barItems[index].date;
                                final label = _selectedPeriod == ReportPeriod.year
                                    ? DateFormat.MMM().format(date)
                                    : DateFormat.Md().format(date);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(label, style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Net Balance Line Chart Card
              if (trendItems.isNotEmpty)
                _ChartCard(
                  title: 'Net Balance Trend',
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final int index = val.toInt();
                                if (index == 0 || index == (trendItems.length - 1) || index == (trendItems.length ~/ 2)) {
                                  final date = trendItems[index].date;
                                  final label = DateFormat.Md().format(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(label, style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: trendItems.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.balance)).toList(),
                            isCurved: true,
                            color: CupertinoColors.systemBlue,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: CupertinoColors.systemBlue.withOpacity(0.1),
                            ),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySystemBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategorySpendingItem {
  final String categoryId;
  final String name;
  final String color;
  final double amount;

  _CategorySpendingItem({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.amount,
  });
}

class _IncomeExpenseItem {
  final DateTime date;
  final double income;
  final double expense;

  _IncomeExpenseItem({
    required this.date,
    required this.income,
    required this.expense,
  });
}

class _BalanceTrendItem {
  final DateTime date;
  final double balance;

  _BalanceTrendItem({
    required this.date,
    required this.balance,
  });
}
