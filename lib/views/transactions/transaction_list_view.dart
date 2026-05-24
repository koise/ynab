import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/transaction_row.dart';
import '../../components/empty_state_view.dart';
import '../../components/floating_action_button.dart';
import '../../components/app_colors.dart';
import 'transaction_detail_view.dart';
import 'add_transaction_sheet.dart';

enum FilterType {
  all('All'),
  income('Income'),
  expense('Expense'),
  transfer('Transfer');

  const FilterType(this.label);
  final String label;
}

class TransactionListView extends StatefulWidget {
  const TransactionListView({Key? key}) : super(key: key);

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  String _searchText = '';
  FilterType _selectedFilter = FilterType.all;

  void _openAddTransaction() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddTransactionSheet(),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? This will revert its effect on your account balance.'),
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

    var filtered = dataStore.transactions;

    if (_selectedFilter != FilterType.all) {
      final label = _selectedFilter.label;
      filtered = filtered.where((t) => t.type.label == label).toList();
    }

    if (_searchText.isNotEmpty) {
      filtered = filtered.where((t) {
        final noteMatch =
            t.note?.toLowerCase().contains(_searchText.toLowerCase()) ?? false;
        final amountMatch =
            t.amount.toStringAsFixed(2).contains(_searchText);
        final category = dataStore.categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => const Category(
              id: '', name: '', icon: '', color: '', type: CategoryType.expense),
        );
        final categoryMatch =
            category.name.toLowerCase().contains(_searchText.toLowerCase());
        return noteMatch || amountMatch || categoryMatch;
      }).toList();
    }

    // Group by date header
    final Map<String, List<Transaction>> grouped = {};
    final DateFormat dayFormat = DateFormat.yMMMMd();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in filtered) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String header;
      if (txDate == today) {
        header = 'Today';
      } else if (txDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = dayFormat.format(tx.date);
      }
      grouped.putIfAbsent(header, () => []).add(tx);
    }

    final List<dynamic> listItems = [];
    grouped.forEach((header, txs) {
      listItems.add(header);
      listItems.addAll(txs);
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Transactions'),
                backgroundColor: AppColors.systemBackground(context),
                border: null,
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: CupertinoSearchTextField(
                    placeholder: 'Search by note, amount, category',
                    onChanged: (val) => setState(() => _searchText = val),
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: FilterType.values.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5B6CF6)
                                  : AppColors.tertiarySystemBackground(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF5B6CF6)
                                    : AppColors.borderColor(context),
                              ),
                            ),
                            child: Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? CupertinoColors.white
                                    : AppColors.label(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Content
              if (listItems.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateView(
                    icon: _searchText.isNotEmpty
                        ? CupertinoIcons.search
                        : CupertinoIcons.creditcard,
                    title: _searchText.isNotEmpty
                        ? 'No Results'
                        : 'No Transactions Yet',
                    subtitle: _searchText.isNotEmpty
                        ? 'Try a different search term or filter.'
                        : 'Tap the + button to add your first transaction.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = listItems[index];

                      if (item is String) {
                        // Date header
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                          child: Text(
                            item.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryLabel(context),
                              letterSpacing: 0.8,
                            ),
                          ),
                        );
                      } else if (item is Transaction) {
                        final category = dataStore.categories.firstWhere(
                          (c) => c.id == item.categoryId,
                          orElse: () => const Category(
                              id: '',
                              name: 'Unknown',
                              icon: '❓',
                              color: '#888888',
                              type: CategoryType.expense),
                        );
                        final account = dataStore.accounts.firstWhere(
                          (a) => a.id == item.accountId,
                          orElse: () => Account(
                              id: '',
                              name: 'Unknown',
                              type: AccountType.cash,
                              balance: 0.0,
                              currency: '',
                              color: '',
                              createdAt: DateTime.now()),
                        );

                        // Determine if this is last in its group
                        final nextItem =
                            index + 1 < listItems.length ? listItems[index + 1] : null;
                        final isLast = nextItem == null || nextItem is String;

                        return Dismissible(
                          key: Key(item.id ?? ''),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (dir) => _confirmDelete(context),
                          onDismissed: (dir) async {
                            if (item.id != null) {
                              await dataStore.deleteTransaction(item.id!);
                            }
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: CupertinoColors.white,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              index > 0 && listItems[index - 1] is String ? 0 : 0,
                              16,
                              isLast ? 4 : 0,
                            ),
                            child: _TransactionTile(
                              transaction: item,
                              category: category,
                              accountName: account.name,
                              currencySymbol: currencySymbol,
                              isDark: isDark,
                              isFirst: index > 0 && listItems[index - 1] is String,
                              isLast: isLast,
                              onTap: () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      TransactionDetailView(transaction: item),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: listItems.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
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

// ─── Transaction Tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final String accountName;
  final String currencySymbol;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.accountName,
    required this.currencySymbol,
    required this.isDark,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground(context),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(14) : Radius.zero,
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
          border: Border(
            left: BorderSide(
              color: AppColors.borderColor(context),
            ),
            right: BorderSide(
              color: AppColors.borderColor(context),
            ),
            top: isFirst
                ? BorderSide(
                    color: AppColors.borderColor(context),
                  )
                : BorderSide.none,
            bottom: isLast
                ? BorderSide(
                    color: AppColors.borderColor(context),
                  )
                : BorderSide(
                    color: AppColors.borderColor(context),
                    width: 0.5),
          ),
        ),
        child: TransactionRow(
          transaction: transaction,
          category: category,
          accountName: accountName,
          currencySymbol: currencySymbol,
        ),
      ),
    );
  }
}
