// models.dart — All data classes, enums, and computed structs.
// Direct Dart translation of Models.swift.

// ─────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────

enum TransactionType {
  income('Income'),
  expense('Expense'),
  transfer('Transfer');

  const TransactionType(this.label);
  final String label;

  factory TransactionType.fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => TransactionType.expense,
    );
  }
}

enum AccountType {
  cash('Cash'),
  bank('Bank'),
  credit('Credit Card'),
  investment('Investment');

  const AccountType(this.label);
  final String label;

  factory AccountType.fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => AccountType.cash,
    );
  }
}

enum CategoryType {
  income('Income'),
  expense('Expense');

  const CategoryType(this.label);
  final String label;

  factory CategoryType.fromString(String value) {
    return CategoryType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => CategoryType.expense,
    );
  }
}

enum RecurringFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RecurringFrequency(this.label);
  final String label;

  factory RecurringFrequency.fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (e) => e.label == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

enum BudgetPeriod {
  weekly('Weekly'),
  monthly('Monthly');

  const BudgetPeriod(this.label);
  final String label;

  factory BudgetPeriod.fromString(String value) {
    return BudgetPeriod.values.firstWhere(
      (e) => e.label == value,
      orElse: () => BudgetPeriod.monthly,
    );
  }
}

enum ColorTheme {
  system('System'),
  light('Light'),
  dark('Dark');

  const ColorTheme(this.label);
  final String label;

  factory ColorTheme.fromString(String value) {
    return ColorTheme.values.firstWhere(
      (e) => e.label == value,
      orElse: () => ColorTheme.system,
    );
  }
}

// ─────────────────────────────────────────────
// ACCOUNT — Firestore: users/{uid}/accounts/{id}
// ─────────────────────────────────────────────

class Account {
  final String? id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final String color;
  final DateTime createdAt;

  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.color,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json, {String? id}) {
    return Account(
      id: id,
      name: json['name'] as String? ?? '',
      type: AccountType.fromString(json['type'] as String? ?? ''),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'PHP',
      color: json['color'] as String? ?? '#2196F3',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['createdAt'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.label,
        'balance': balance,
        'currency': currency,
        'color': color,
        'createdAt': createdAt,
      };

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    String? color,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY — Firestore: users/{uid}/categories/{id}
// ─────────────────────────────────────────────

class Category {
  final String? id;
  final String name;
  final String icon;   // CupertinoIcons name or emoji
  final String color;  // hex string
  final CategoryType type;

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json, {String? id}) {
    return Category(
      id: id,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '📦',
      color: json['color'] as String? ?? '#607D8B',
      type: CategoryType.fromString(json['type'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'color': color,
        'type': type.label,
      };

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    CategoryType? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }
}

// ─────────────────────────────────────────────
// TRANSACTION — Firestore: users/{uid}/transactions/{id}
// ─────────────────────────────────────────────

class Transaction {
  final String? id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? toAccountId; // for transfers
  final DateTime date;
  final String? note;
  final bool isRecurring;
  final String? recurringId;

  const Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, {String? id}) {
    return Transaction(
      id: id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(json['type'] as String? ?? ''),
      categoryId: json['categoryId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      toAccountId: json['toAccountId'] as String?,
      date: json['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['date'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      note: json['note'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'type': type.label,
        'categoryId': categoryId,
        'accountId': accountId,
        if (toAccountId != null) 'toAccountId': toAccountId,
        'date': date,
        if (note != null) 'note': note,
        'isRecurring': isRecurring,
        if (recurringId != null) 'recurringId': recurringId,
      };

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    bool? isRecurring,
    String? recurringId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
    );
  }
}

// ─────────────────────────────────────────────
// RECURRING RULE — Firestore: users/{uid}/recurringRules/{id}
// ─────────────────────────────────────────────

class RecurringRule {
  final String? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;

  const RecurringRule({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
  });

  factory RecurringRule.fromJson(Map<String, dynamic> json, {String? id}) {
    return RecurringRule(
      id: id,
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(json['type'] as String? ?? ''),
      categoryId: json['categoryId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      frequency: RecurringFrequency.fromString(json['frequency'] as String? ?? ''),
      startDate: json['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['startDate'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['nextDueDate'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'type': type.label,
        'categoryId': categoryId,
        'accountId': accountId,
        'frequency': frequency.label,
        'startDate': startDate,
        'nextDueDate': nextDueDate,
        'isActive': isActive,
      };

  RecurringRule copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ─────────────────────────────────────────────
// BUDGET — Firestore: users/{uid}/budgets/{id}
// ─────────────────────────────────────────────

class Budget {
  final String? id;
  final String categoryId;
  final double limit;
  final BudgetPeriod period;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.categoryId,
    required this.limit,
    required this.period,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json, {String? id}) {
    return Budget(
      id: id,
      categoryId: json['categoryId'] as String? ?? '',
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      period: BudgetPeriod.fromString(json['period'] as String? ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['createdAt'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'limit': limit,
        'period': period.label,
        'createdAt': createdAt,
      };

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ─────────────────────────────────────────────
// BUDGET PROGRESS — computed locally, not persisted
// ─────────────────────────────────────────────

class BudgetProgress {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentUsed;
  final bool isOverBudget;

  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
  });
}

// ─────────────────────────────────────────────
// USER SETTINGS — Firestore: users/{uid}/settings/preferences
// ─────────────────────────────────────────────

class UserSettings {
  final String currency;
  final String currencySymbol;
  final bool isPINEnabled;
  final bool isBiometricEnabled;
  final ColorTheme colorTheme;
  final bool notificationsEnabled;

  const UserSettings({
    required this.currency,
    required this.currencySymbol,
    required this.isPINEnabled,
    required this.isBiometricEnabled,
    required this.colorTheme,
    required this.notificationsEnabled,
  });

  static const UserSettings defaults = UserSettings(
    currency: 'PHP',
    currencySymbol: '₱',
    isPINEnabled: false,
    isBiometricEnabled: false,
    colorTheme: ColorTheme.system,
    notificationsEnabled: true,
  );

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: json['currency'] as String? ?? 'PHP',
      currencySymbol: json['currencySymbol'] as String? ?? '₱',
      isPINEnabled: json['isPINEnabled'] as bool? ?? false,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      colorTheme: ColorTheme.fromString(json['colorTheme'] as String? ?? ''),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'currencySymbol': currencySymbol,
        'isPINEnabled': isPINEnabled,
        'isBiometricEnabled': isBiometricEnabled,
        'colorTheme': colorTheme.label,
        'notificationsEnabled': notificationsEnabled,
      };

  UserSettings copyWith({
    String? currency,
    String? currencySymbol,
    bool? isPINEnabled,
    bool? isBiometricEnabled,
    ColorTheme? colorTheme,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isPINEnabled: isPINEnabled ?? this.isPINEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      colorTheme: colorTheme ?? this.colorTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// ─────────────────────────────────────────────
// YNAB ERRORS
// ─────────────────────────────────────────────

class YNABError implements Exception {
  final String message;
  const YNABError(this.message);

  factory YNABError.accountHasTransactions(int count) => YNABError(
        'Cannot delete account with $count linked transaction${count == 1 ? '' : 's'}. '
        'Reassign or delete them first.',
      );

  factory YNABError.categoryHasTransactions(int count) => YNABError(
        'Cannot delete category with $count linked transaction${count == 1 ? '' : 's'}. '
        'Reassign them first.',
      );

  static const YNABError notAuthenticated = YNABError(
    'User is not authenticated. Please sign in first.',
  );

  @override
  String toString() => message;
}
