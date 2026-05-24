import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/app_colors.dart';
import 'add_transaction_sheet.dart';

class TransactionDetailView extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailView({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  String get _amountPrefix {
    switch (transaction.type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
        return '-';
      case TransactionType.transfer:
        return '';
    }
  }

  Color get _amountColor {
    switch (transaction.type) {
      case TransactionType.income:
        return CupertinoColors.systemGreen;
      case TransactionType.expense:
        return CupertinoColors.label;
      case TransactionType.transfer:
        return CupertinoColors.systemBlue;
    }
  }

  Future<void> _deleteTransaction(BuildContext context, DataStore dataStore) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This will revert its effect on your account balance.'),
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

    if (confirm == true && transaction.id != null) {
      await dataStore.deleteTransaction(transaction.id!);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final category = dataStore.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => const Category(id: '', name: 'Transfer', icon: '🔁', color: '#2196F3', type: CategoryType.expense),
    );

    final account = dataStore.accounts.firstWhere(
      (a) => a.id == transaction.accountId,
      orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()),
    );

    final toAccount = transaction.toAccountId != null
        ? dataStore.accounts.firstWhere(
            (a) => a.id == transaction.toAccountId,
            orElse: () => Account(id: '', name: 'Unknown', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now()),
          )
        : null;

    final formattedDate = DateFormat.yMMMMd().add_jm().format(transaction.date);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Transaction Details',
          style: TextStyle(color: AppColors.label(context)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Edit'),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (_) => AddTransactionSheet(
                  isEditing: true,
                  existingTransaction: transaction,
                ),
              ),
            );
          },
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.hexToColor(category.color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _buildIcon(category),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_amountPrefix${dataStore.userSettings.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _amountColor == CupertinoColors.label ? AppColors.label(context) : _amountColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryLabel(context),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.secondarySystemBackground(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, 'Type', transaction.type.label),
                  _buildDivider(context),
                  _buildDetailRow(
                    context,
                    transaction.type == TransactionType.transfer ? 'From' : 'Account',
                    account.name,
                  ),
                  if (transaction.type == TransactionType.transfer && toAccount != null) ...[
                    _buildDivider(context),
                    _buildDetailRow(context, 'To', toAccount.name),
                  ],
                  _buildDivider(context),
                  _buildDetailRow(context, 'Date', formattedDate),
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    _buildDivider(context),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.secondaryLabel(context),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              transaction.note!,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.label(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),
            CupertinoButton(
              color: AppColors.secondarySystemBackground(context),
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _deleteTransaction(context, dataStore),
              child: const Text(
                'Delete Transaction',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Category category) {
    final bool isEmoji = category.icon.runes.any((r) => r > 127);
    if (isEmoji) {
      return Text(
        category.icon,
        style: const TextStyle(fontSize: 40),
      );
    }
    IconData iconData = CupertinoIcons.question;
    switch (category.icon) {
      case 'banknote':
      case 'banknote.fill':
        iconData = CupertinoIcons.money_dollar_circle;
        break;
      case 'building.columns':
      case 'building.columns.fill':
        iconData = CupertinoIcons.house_alt;
        break;
      case 'creditcard':
      case 'creditcard.fill':
        iconData = CupertinoIcons.creditcard;
        break;
      case 'chart.line.uptrend.xyaxis':
        iconData = CupertinoIcons.graph_square;
        break;
      case 'gear':
        iconData = CupertinoIcons.settings;
        break;
      case 'house':
      case 'house.fill':
        iconData = CupertinoIcons.home;
        break;
      case 'tag':
      case 'tag.fill':
        iconData = CupertinoIcons.tag;
        break;
    }
    return Icon(iconData, color: AppColors.hexToColor(category.color), size: 40);
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryLabel(context),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.label(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}
