import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../services/budget_service.dart';
import '../../models/models.dart';
import '../../components/balance_card.dart';
import '../../components/empty_state_view.dart';
import '../../components/transaction_row.dart';
import '../../components/floating_action_button.dart';
import '../../components/app_colors.dart';
import '../transactions/transaction_list_view.dart';
import '../transactions/transaction_detail_view.dart';
import '../transactions/add_transaction_sheet.dart';
import '../budgets/budget_list_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  void _openAddTransaction() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddTransactionSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final alerts = BudgetService.progress(
      budgets: dataStore.budgets,
      transactions: dataStore.transactions,
    ).where((p) => p.percentUsed >= 0.75).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Dashboard'),
                backgroundColor: AppColors.systemBackground(context),
                border: null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceCard(
                        totalBalance: dataStore.totalBalance,
                        income: dataStore.thisMonthIncome,
                        expense: dataStore.thisMonthExpenses,
                        currencySymbol: currencySymbol,
                      ),
                      const SizedBox(height: 28),

                      // ── Budget Alerts ──────────────────────────────────
                      if (alerts.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Budget Alerts',
                          icon: CupertinoIcons.exclamationmark_circle_fill,
                          iconColor: CupertinoColors.systemOrange,
                        ),
                        const SizedBox(height: 10),
                        ...alerts.map((progress) {
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                    builder: (_) => const BudgetListView()),
                              ),
                              child: _AlertCard(
                                icon: category.icon,
                                name: category.name,
                                progress: progress,
                                isDark: isDark,
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],

                      // ── Recent Transactions ────────────────────────────
                      _SectionHeader(
                        title: 'Recent Transactions',
                        icon: CupertinoIcons.clock_fill,
                        iconColor: const Color(0xFF5B6CF6),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                                builder: (_) => const TransactionListView()),
                          ),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF5B6CF6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (dataStore.recentTransactions.isEmpty)
                        const EmptyStateView(
                          icon: CupertinoIcons.list_bullet_indent,
                          title: 'No Transactions Yet',
                          subtitle:
                              'Tap the + button to record your first transaction.',
                        )
                      else
                        _TransactionCard(
                          transactions: dataStore.recentTransactions,
                          dataStore: dataStore,
                          currencySymbol: currencySymbol,
                          isDark: isDark,
                        ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // FAB
          Positioned(
            bottom: 90,
            right: 24,
            child: AppFAB(
              onTap: _openAddTransaction,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.label(context),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final String icon;
  final String name;
  final dynamic progress;
  final bool isDark;

  const _AlertCard({
    required this.icon,
    required this.name,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool over = progress.isOverBudget as bool;
    final color =
        over ? CupertinoColors.systemRed : CupertinoColors.systemOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.label(context),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              over
                  ? 'Over budget!'
                  : '${((progress.percentUsed as double) * 100).toInt()}% used',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Card Container ───────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final List<Transaction> transactions;
  final DataStore dataStore;
  final String currencySymbol;
  final bool isDark;

  const _TransactionCard({
    required this.transactions,
    required this.dataStore,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondarySystemBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor(context),
        ),
      ),
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final tx = entry.value;
          final category = dataStore.categories.firstWhere(
            (c) => c.id == tx.categoryId,
            orElse: () => const Category(
                id: '',
                name: 'Unknown',
                icon: '❓',
                color: '#888888',
                type: CategoryType.expense),
          );
          final account = dataStore.accounts.firstWhere(
            (a) => a.id == tx.accountId,
            orElse: () => Account(
                id: '',
                name: 'Unknown',
                type: AccountType.cash,
                balance: 0.0,
                currency: '',
                color: '',
                createdAt: DateTime.now()),
          );

          return Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => TransactionDetailView(transaction: tx),
                  ),
                ),
                child: Container(
                  color: CupertinoColors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TransactionRow(
                    transaction: tx,
                    category: category,
                    accountName: account.name,
                    currencySymbol: currencySymbol,
                  ),
                ),
              ),
              if (i < transactions.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
