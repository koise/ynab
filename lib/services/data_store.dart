import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import 'firebase_service.dart';
import 'budget_service.dart';
import 'recurring_service.dart';
import 'notification_service.dart';

/// Central source of truth — aggregates all Firestore listeners and
/// exposes CRUD with balance integrity.
/// Mirrors DataStore.swift.
class DataStore extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  // ─── State ────────────────────────────────

  List<Account> accounts = [];
  List<Category> categories = [];
  List<Transaction> transactions = [];
  List<RecurringRule> recurringRules = [];
  List<Budget> budgets = [];
  UserSettings userSettings = UserSettings.defaults;
  bool isLoading = true;

  // ─── Collection names ─────────────────────

  static const _accounts = 'accounts';
  static const _categories = 'categories';
  static const _transactions = 'transactions';
  static const _recurringRules = 'recurringRules';
  static const _budgets = 'budgets';
  static const _settings = 'settings';

  // ─── Stream subscriptions ─────────────────

  final List<StreamSubscription> _subs = [];

  // ─── Listener Management ──────────────────

  void startListening() {
    stopListening();

    _subs.add(_firebase.listen(_accounts).listen((docs) {
      accounts = docs.map((d) => Account.fromJson(d, id: d['id'] as String?)).toList();
      notifyListeners();
    }));

    _subs.add(_firebase.listen(_categories).listen((docs) {
      categories = docs.map((d) => Category.fromJson(d, id: d['id'] as String?)).toList();
      notifyListeners();
    }));

    _subs.add(_firebase.listen(_transactions).listen((docs) {
      transactions = docs
          .map((d) => Transaction.fromJson(d, id: d['id'] as String?))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _checkBudgetAlerts();
      notifyListeners();
    }));

    _subs.add(_firebase.listen(_recurringRules).listen((docs) {
      recurringRules = docs.map((d) => RecurringRule.fromJson(d, id: d['id'] as String?)).toList();
      notifyListeners();
    }));

    _subs.add(_firebase.listen(_budgets).listen((docs) {
      budgets = docs.map((d) => Budget.fromJson(d, id: d['id'] as String?)).toList();
      _checkBudgetAlerts();
      notifyListeners();
    }));

    _subs.add(_firebase.listenToDocument(_settings, 'preferences').listen((data) {
      userSettings = data != null ? UserSettings.fromJson(data) : UserSettings.defaults;
      _migratePinIfNeeded();
      isLoading = false;
      notifyListeners();
    }));
  }

  void stopListening() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  // ─── Accounts ─────────────────────────────

  Future<void> addAccount(Account account) async {
    await _firebase.add(account.toJson(), _accounts);
  }

  Future<void> updateAccount(Account account) async {
    if (account.id == null) return;
    await _firebase.update(account.toJson(), _accounts, account.id!);
  }

  Future<void> deleteAccount(String id) async {
    final linked = transactions.where(
      (t) => t.accountId == id || t.toAccountId == id,
    ).toList();
    if (linked.isNotEmpty) {
      throw YNABError.accountHasTransactions(linked.length);
    }
    await _firebase.delete(_accounts, id);
  }

  // ─── Categories ───────────────────────────

  Future<void> addCategory(Category category) async {
    await _firebase.add(category.toJson(), _categories);
  }

  Future<void> updateCategory(Category category) async {
    if (category.id == null) return;
    await _firebase.update(category.toJson(), _categories, category.id!);
  }

  Future<void> deleteCategory(String id) async {
    final linked = transactions.where((t) => t.categoryId == id).toList();
    if (linked.isNotEmpty) {
      throw YNABError.categoryHasTransactions(linked.length);
    }
    // Cascade: delete budgets for this category
    for (final budget in budgets.where((b) => b.categoryId == id)) {
      if (budget.id != null) await _firebase.delete(_budgets, budget.id!);
    }
    await _firebase.delete(_categories, id);
  }

  // ─── Transactions (with balance integrity) ─

  Future<void> addTransaction(Transaction transaction) async {
    await _firebase.add(transaction.toJson(), _transactions);
    await _applyBalanceEffect(transaction);
  }

  Future<void> updateTransaction({
    required Transaction oldTx,
    required Transaction newTx,
  }) async {
    if (newTx.id == null) return;
    await _reverseBalanceEffect(oldTx);
    await _firebase.update(newTx.toJson(), _transactions, newTx.id!);
    await _applyBalanceEffect(newTx);
  }

  Future<void> deleteTransaction(String id) async {
    final tx = transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Transaction not found'),
    );
    await _reverseBalanceEffect(tx);
    await _firebase.delete(_transactions, id);
  }

  // ─── Balance Integrity ────────────────────

  Future<void> _applyBalanceEffect(Transaction txn) async {
    final accountIndex = accounts.indexWhere((a) => a.id == txn.accountId);
    if (accountIndex == -1) return;

    final account = accounts[accountIndex];
    double newBalance = account.balance;

    switch (txn.type) {
      case TransactionType.income:
        newBalance += txn.amount;
      case TransactionType.expense:
        newBalance -= txn.amount;
      case TransactionType.transfer:
        newBalance -= txn.amount;
        if (txn.toAccountId != null) {
          final toIndex = accounts.indexWhere((a) => a.id == txn.toAccountId);
          if (toIndex != -1) {
            final to = accounts[toIndex];
            await _firebase.update(
              to.copyWith(balance: to.balance + txn.amount).toJson(),
              _accounts,
              to.id!,
            );
          }
        }
    }

    await _firebase.update(
      account.copyWith(balance: newBalance).toJson(),
      _accounts,
      account.id!,
    );
  }

  Future<void> _reverseBalanceEffect(Transaction txn) async {
    final accountIndex = accounts.indexWhere((a) => a.id == txn.accountId);
    if (accountIndex == -1) return;

    final account = accounts[accountIndex];
    double newBalance = account.balance;

    switch (txn.type) {
      case TransactionType.income:
        newBalance -= txn.amount;
      case TransactionType.expense:
        newBalance += txn.amount;
      case TransactionType.transfer:
        newBalance += txn.amount;
        if (txn.toAccountId != null) {
          final toIndex = accounts.indexWhere((a) => a.id == txn.toAccountId);
          if (toIndex != -1) {
            final to = accounts[toIndex];
            await _firebase.update(
              to.copyWith(balance: to.balance - txn.amount).toJson(),
              _accounts,
              to.id!,
            );
          }
        }
    }

    await _firebase.update(
      account.copyWith(balance: newBalance).toJson(),
      _accounts,
      account.id!,
    );
  }

  // ─── Transfers ────────────────────────────

  Future<void> addTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    final tx = Transaction(
      amount: amount,
      type: TransactionType.transfer,
      categoryId: '',
      accountId: fromAccountId,
      toAccountId: toAccountId,
      date: date,
      note: note,
      isRecurring: false,
    );
    await addTransaction(tx);
  }

  // ─── Budgets ──────────────────────────────

  Future<void> addBudget(Budget budget) async {
    await _firebase.add(budget.toJson(), _budgets);
  }

  Future<void> updateBudget(Budget budget) async {
    if (budget.id == null) return;
    await _firebase.update(budget.toJson(), _budgets, budget.id!);
  }

  Future<void> deleteBudget(String id) async {
    await _firebase.delete(_budgets, id);
  }

  // ─── Recurring Rules ──────────────────────

  Future<void> addRecurringRule(RecurringRule rule) async {
    final id = await _firebase.add(rule.toJson(), _recurringRules);
    if (userSettings.notificationsEnabled) {
      NotificationService.scheduleRecurringReminder(
        rule: rule.copyWith(id: id),
        currencySymbol: userSettings.currencySymbol,
      );
    }
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    if (rule.id == null) return;
    await _firebase.update(rule.toJson(), _recurringRules, rule.id!);
  }

  Future<void> deleteRecurringRule(String id) async {
    await _firebase.delete(_recurringRules, id);
    NotificationService.cancelRecurringReminder(ruleId: id);
  }

  Future<void> toggleRecurringRule(RecurringRule rule) async {
    await updateRecurringRule(rule.copyWith(isActive: !rule.isActive));
  }

  // ─── User Settings ────────────────────────

  Future<void> updateSettings(UserSettings settings) async {
    await _firebase.setPreferences(settings.toJson());
  }

  // ─── Seed Data ────────────────────────────

  Future<void> seedDefaultDataIfNeeded() async {
    final existing = await _firebase.fetch(_accounts);
    if (existing.isNotEmpty) return;

    // Default accounts
    for (final account in [
      Account(name: 'Cash Wallet', type: AccountType.cash, balance: 0,
          currency: 'PHP', color: '#4CAF50', createdAt: DateTime.now()),
      Account(name: 'Bank Account', type: AccountType.bank, balance: 0,
          currency: 'PHP', color: '#2196F3', createdAt: DateTime.now()),
    ]) {
      await _firebase.add(account.toJson(), _accounts);
    }

    // Default expense categories
    for (final cat in [
      Category(name: 'Food', icon: '🍔', color: '#FF9800', type: CategoryType.expense),
      Category(name: 'Transport', icon: '🚌', color: '#03A9F4', type: CategoryType.expense),
      Category(name: 'Housing', icon: '🏠', color: '#795548', type: CategoryType.expense),
      Category(name: 'Health', icon: '💊', color: '#F44336', type: CategoryType.expense),
      Category(name: 'Entertainment', icon: '🎮', color: '#9C27B0', type: CategoryType.expense),
      Category(name: 'Shopping', icon: '🛍️', color: '#E91E63', type: CategoryType.expense),
      Category(name: 'Education', icon: '📚', color: '#3F51B5', type: CategoryType.expense),
      Category(name: 'Others', icon: '📦', color: '#607D8B', type: CategoryType.expense),
      // Income categories
      Category(name: 'Salary', icon: '💼', color: '#4CAF50', type: CategoryType.income),
      Category(name: 'Freelance', icon: '💰', color: '#8BC34A', type: CategoryType.income),
      Category(name: 'Gift', icon: '🎁', color: '#FF5722', type: CategoryType.income),
      Category(name: 'Investment', icon: '📈', color: '#009688', type: CategoryType.income),
      Category(name: 'Others', icon: '💵', color: '#CDDC39', type: CategoryType.income),
    ]) {
      await _firebase.add(cat.toJson(), _categories);
    }

    await updateSettings(UserSettings.defaults);
  }

  /// Process due recurring transactions and apply them.
  Future<void> processDueTransactions() async {
    final due = RecurringService.processDueTransactions(recurringRules);
    for (final item in due) {
      await addTransaction(item.transaction);
      // Advance nextDueDate on the rule
      final updated = item.rule.copyWith(
        nextDueDate: RecurringService.advanceDate(
          item.rule.nextDueDate,
          item.rule.frequency,
        ),
      );
      await updateRecurringRule(updated);
    }
  }

  // ─── PIN Migration ────────────────────────

  Future<void> _migratePinIfNeeded() async {
    // No-op in Flutter — PIN was never stored in Firestore
    // flutter_secure_storage handles it natively
  }

  // ─── Budget Alerts ────────────────────────

  void _checkBudgetAlerts() {
    if (!userSettings.notificationsEnabled) return;
    final progresses = BudgetService.progress(
      budgets: budgets,
      transactions: transactions,
    );
    for (final p in progresses) {
      if (p.percentUsed >= 0.75) {
        final categoryName = categories
            .firstWhere(
              (c) => c.id == p.budget.categoryId,
              orElse: () => const Category(
                  name: 'Category', icon: '', color: '', type: CategoryType.expense),
            )
            .name;
        NotificationService.scheduleBudgetAlert(
          categoryName: categoryName,
          percentUsed: p.percentUsed,
          remaining: p.remaining,
          currencySymbol: userSettings.currencySymbol,
        );
      }
    }
  }

  // ─── Computed Properties ──────────────────

  double get totalBalance => accounts.fold(0.0, (sum, a) => sum + a.balance);

  double get thisMonthIncome {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get thisMonthExpenses {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<Transaction> get recentTransactions => transactions.take(5).toList();
}
