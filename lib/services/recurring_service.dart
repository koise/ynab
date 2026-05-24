import '../models/models.dart';

/// Processes overdue recurring rules and generates Transactions.
/// Mirrors RecurringService.swift.
class RecurringService {
  /// Returns list of new Transactions to create for any overdue rules.
  static List<({RecurringRule rule, Transaction transaction})> processDueTransactions(
    List<RecurringRule> rules,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <({RecurringRule rule, Transaction transaction})>[];

    for (final rule in rules) {
      if (!rule.isActive) continue;

      var nextDue = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );

      // Process all overdue dates (catches up if app was closed for multiple periods)
      while (!nextDue.isAfter(today)) {
        final transaction = Transaction(
          amount: rule.amount,
          type: rule.type,
          categoryId: rule.categoryId,
          accountId: rule.accountId,
          date: nextDue,
          note: rule.title,
          isRecurring: true,
          recurringId: rule.id,
        );
        results.add((rule: rule, transaction: transaction));
        nextDue = advanceDate(nextDue, rule.frequency);
      }
    }

    return results;
  }

  /// Advances a date by the given frequency.
  static DateTime advanceDate(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurringFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}
