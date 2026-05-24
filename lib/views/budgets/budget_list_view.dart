import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../services/budget_service.dart';
import '../../models/models.dart';
import '../../components/budget_progress_bar.dart';
import '../../components/empty_state_view.dart';
import '../../components/floating_action_button.dart';
import '../../components/app_colors.dart';
import 'add_budget_sheet.dart';

class BudgetListView extends StatefulWidget {
  const BudgetListView({Key? key}) : super(key: key);

  @override
  State<BudgetListView> createState() => _BudgetListViewState();
}

class _BudgetListViewState extends State<BudgetListView> {
  void _openAddBudget() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddBudgetSheet(),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
            'Are you sure you want to delete this budget limit? This will not delete your transactions.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final progresses = BudgetService.progress(
      budgets: dataStore.budgets,
      transactions: dataStore.transactions,
    );

    final double totalBudgeted =
        dataStore.budgets.fold(0.0, (sum, b) => sum + b.limit);
    final double totalSpent =
        progresses.fold(0.0, (sum, p) => sum + p.spent);
    final double remaining =
        (totalBudgeted - totalSpent).clamp(0.0, double.infinity);
    final double overallPercent =
        totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Budgets'),
                backgroundColor: AppColors.systemBackground(context),
                border: null,
              ),

              if (dataStore.budgets.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateView(
                    icon: CupertinoIcons.chart_pie_fill,
                    title: 'No Budgets Yet',
                    subtitle:
                        'Set spending limits to stay on track with your goals.',
                    action: GestureDetector(
                      onTap: _openAddBudget,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B6CF6), Color(0xFF9B59B6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Create Budget',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _SummaryCard(
                      currencySymbol: currencySymbol,
                      totalBudgeted: totalBudgeted,
                      totalSpent: totalSpent,
                      remaining: remaining,
                      overallPercent: overallPercent,
                      isDark: isDark,
                    ),
                  ),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B6CF6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.scope,
                            size: 15,
                            color: Color(0xFF5B6CF6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Spending Limits',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.label(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progresses.length} active',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Budget list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final progress = progresses[index];
                      final category = dataStore.categories.firstWhere(
                        (c) => c.id == progress.budget.categoryId,
                        orElse: () => const Category(
                            id: '',
                            name: 'Unknown',
                            icon: '❓',
                            color: '#888888',
                            type: CategoryType.expense),
                      );

                      if (category.id == null || category.id!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Dismissible(
                        key: Key(progress.budget.id ?? ''),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (dir) => _confirmDelete(context),
                        onDismissed: (dir) async {
                          if (progress.budget.id != null) {
                            await dataStore.deleteBudget(progress.budget.id!);
                          }
                        },
                        background: Container(
                          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: CupertinoColors.white,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondarySystemBackground(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderColor(context),
                              ),
                            ),
                            child: BudgetProgressBar(
                              progress: progress,
                              categoryName: category.name,
                              categoryIcon: category.icon,
                              categoryColor: category.color,
                              currencySymbol: currencySymbol,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: progresses.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),

          // FAB
          Positioned(
            bottom: 90,
            right: 24,
            child: AppFAB(
              onTap: _openAddBudget,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String currencySymbol;
  final double totalBudgeted;
  final double totalSpent;
  final double remaining;
  final double overallPercent;
  final bool isDark;

  const _SummaryCard({
    required this.currencySymbol,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.remaining,
    required this.overallPercent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOver = overallPercent >= 1.0;
    final barColor = isOver
        ? CupertinoColors.systemRed
        : overallPercent >= 0.75
            ? CupertinoColors.systemOrange
            : const Color(0xFF5B6CF6);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F1F2E), const Color(0xFF14141F)]
              : [const Color(0xFFEEF0FF), const Color(0xFFF5F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor(context),
        ),
      ),
      child: Column(
        children: [
          // Main figures
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryLabel(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol${totalBudgeted.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.label(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Remaining badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOver
                      ? CupertinoColors.systemRed.withOpacity(0.12)
                      : CupertinoColors.systemGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOver
                        ? CupertinoColors.systemRed.withOpacity(0.3)
                        : CupertinoColors.systemGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isOver ? 'Over!' : 'Left',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOver
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currencySymbol${remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isOver
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: AppColors.tertiarySystemBackground(context),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: overallPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Spent / Remaining row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                label: 'Spent',
                value: '$currencySymbol${totalSpent.toStringAsFixed(2)}',
                color: CupertinoColors.systemRed,
              ),
              Text(
                '${(overallPercent * 100).toStringAsFixed(0)}% used',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryLabel(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              _StatChip(
                label: 'Remaining',
                value: '$currencySymbol${remaining.toStringAsFixed(2)}',
                color: CupertinoColors.systemGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.secondaryLabel(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
