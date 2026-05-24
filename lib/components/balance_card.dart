import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double income;
  final double expense;
  final String currencySymbol;

  const BalanceCard({
    Key? key,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F1F2E), const Color(0xFF14141F)]
              : [const Color(0xFFEBF3FE), const Color(0xFFF6F8FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFE2EAF5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryLabel(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$currencySymbol${totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.label(context),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Income
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_down_left_circle_fill,
                          color: AppColors.income,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currencySymbol${income.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFE2EAF5),
              ),
              // Expense
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_up_right_circle_fill,
                          color: AppColors.expense,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currencySymbol${expense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.expense,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
