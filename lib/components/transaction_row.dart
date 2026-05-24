import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import 'app_colors.dart';
import 'package:intl/intl.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final String accountName;
  final String currencySymbol;

  const TransactionRow({
    Key? key,
    required this.transaction,
    required this.category,
    required this.accountName,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color catColor = category != null
        ? AppColors.hexToColor(category!.color)
        : CupertinoColors.systemGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon ZStack equivalent
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _buildIcon(context),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category?.name ?? (transaction.type == TransactionType.transfer ? 'Transfer' : 'Unknown'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.label(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        accountName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLabel(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryLabel(context),
                      ),
                    ),
                    Text(
                      DateFormat.jm().format(transaction.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryLabel(context),
                      ),
                    ),
                  ],
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryLabel(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Text(
            '$_amountPrefix$currencySymbol${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (category == null || category!.icon.isEmpty) {
      return Icon(CupertinoIcons.question, color: AppColors.hexToColor(category?.color ?? '#888888'), size: 20);
    }
    final bool isEmoji = category!.icon.runes.any((r) => r > 127);
    if (isEmoji) {
      return Text(
        category!.icon,
        style: const TextStyle(fontSize: 22),
      );
    }

    return Icon(
      AppColors.getCupertinoIcon(category!.icon),
      color: AppColors.hexToColor(category!.color),
      size: 20,
    );
  }

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
        return CupertinoColors.systemRed;
      case TransactionType.transfer:
        return CupertinoColors.systemBlue;
    }
  }
}
