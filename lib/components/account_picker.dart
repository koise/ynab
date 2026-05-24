import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import 'app_colors.dart';

class AccountPicker extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountSelected;

  const AccountPicker({
    Key? key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: accounts.map((account) {
        final isSelected = account.id == selectedAccountId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onAccountSelected(account.id),
            child: AccountCell(
              account: account,
              isSelected: isSelected,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AccountCell extends StatelessWidget {
  final Account account;
  final bool isSelected;

  const AccountCell({
    Key? key,
    required this.account,
    required this.isSelected,
  }) : super(key: key);

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
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color accColor = AppColors.hexToColor(account.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? CupertinoColors.activeBlue.withOpacity(0.1)
            : AppColors.secondarySystemBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? CupertinoColors.activeBlue
              : (isDark ? const Color(0xFF2C2C3E) : CupertinoColors.transparent),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconFor(account.type),
            color: accColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.label(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.type.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${account.currency}${account.balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.label(context),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.checkmark_alt,
              color: CupertinoColors.activeBlue,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
