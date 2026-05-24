import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/empty_state_view.dart';
import '../../components/app_colors.dart';
import '../../components/transaction_row.dart';
import '../transactions/transaction_detail_view.dart';
import 'add_account_sheet.dart';

class AccountListView extends StatefulWidget {
  const AccountListView({Key? key}) : super(key: key);

  @override
  State<AccountListView> createState() => _AccountListViewState();
}

class _AccountListViewState extends State<AccountListView> {
  void _openAddAccount() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddAccountSheet(),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, DataStore dataStore, Account account) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"? This will delete the account from your profile.'),
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

    if (confirm == true && account.id != null) {
      try {
        await dataStore.deleteAccount(account.id!);
      } catch (e) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Cannot Delete'),
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  IconData _iconFor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return CupertinoIcons.money_dollar_circle_fill;
      case AccountType.bank:
        return CupertinoIcons.house_alt_fill;
      case AccountType.credit:
        return CupertinoIcons.creditcard_fill;
      case AccountType.investment:
        return CupertinoIcons.graph_square_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Accounts',
          style: TextStyle(color: AppColors.label(context)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.plus),
          onPressed: _openAddAccount,
        ),
        border: null,
      ),
      child: SafeArea(
        child: dataStore.accounts.isEmpty
            ? const Center(
                child: EmptyStateView(
                  icon: CupertinoIcons.building_2_fill,
                  title: 'No Accounts',
                  subtitle: 'Add your first account to get started.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: dataStore.accounts.length,
                itemBuilder: (context, index) {
                  final account = dataStore.accounts[index];
                  final Color accColor = AppColors.hexToColor(account.color);

                  return Dismissible(
                    key: Key(account.id ?? ''),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (dir) async {
                      await _deleteAccount(context, dataStore, account);
                      return false; // manually handle
                    },
                    background: Container(
                      color: CupertinoColors.systemRed,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.white,
                      ),
                    ),
                    child: CupertinoListSection.insetGrouped(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: [
                        CupertinoListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => AccountTransactionListView(account: account),
                              ),
                            );
                          },
                          leading: Icon(
                            _iconFor(account.type),
                            color: accColor,
                            size: 28,
                          ),
                          title: Text(
                            account.name,
                            style: TextStyle(color: AppColors.label(context)),
                          ),
                          subtitle: Text(
                            account.type.label,
                            style: TextStyle(color: AppColors.secondaryLabel(context)),
                          ),
                          trailing: const CupertinoListTileChevron(),
                          additionalInfo: Text(
                            '${account.currency}${account.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.label(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class AccountTransactionListView extends StatelessWidget {
  final Account account;

  const AccountTransactionListView({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final accountTransactions = dataStore.transactions.where((t) {
      return t.accountId == account.id || t.toAccountId == account.id;
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          account.name,
          style: TextStyle(color: AppColors.label(context)),
        ),
        border: null,
      ),
      child: SafeArea(
        child: accountTransactions.isEmpty
            ? const Center(
                child: EmptyStateView(
                  icon: CupertinoIcons.list_bullet,
                  title: 'No Transactions',
                  subtitle: 'No transactions found for this account.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: accountTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = accountTransactions[index];
                  final category = dataStore.categories.firstWhere(
                    (c) => c.id == transaction.categoryId,
                    orElse: () => const Category(id: '', name: 'Transfer', icon: '🔁', color: '#2196F3', type: CategoryType.expense),
                  );

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => TransactionDetailView(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          color: CupertinoColors.transparent,
                          child: TransactionRow(
                            transaction: transaction,
                            category: category,
                            accountName: account.name,
                            currencySymbol: dataStore.userSettings.currencySymbol,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        height: 0.5,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
