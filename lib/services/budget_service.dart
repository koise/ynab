import '../models/models.dart';

/// Stateless budget progress calculator.
/// Mirrors BudgetService.swift.
class BudgetService {
  /// Computes progress for each budget against the provided transactions.
  static List<BudgetProgress> progress({
    required List<Budget> budgets,
    required List<Transaction> transactions,
  }) {
    final now = DateTime.now();

    return budgets.map((budget) {
      final periodStart = _periodStart(budget.period, now);

      final spent = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == budget.categoryId &&
              t.date.isAfter(periodStart))
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final remaining = budget.limit - spent;
      final percentUsed = budget.limit > 0 ? spent / budget.limit : 0.0;

      return BudgetProgress(
        budget: budget,
        spent: spent,
        remaining: remaining,
        percentUsed: percentUsed,
        isOverBudget: spent > budget.limit,
      );
    }).toList();
  }

  static DateTime _periodStart(BudgetPeriod period, DateTime now) {
    switch (period) {
      case BudgetPeriod.weekly:
        // Start of this week (Monday)
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - (weekday - 1));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }
}
