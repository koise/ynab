import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../services/recurring_service.dart';
import '../../models/models.dart';
import '../../components/amount_text_field.dart';
import '../../components/category_picker.dart';
import '../../components/app_colors.dart';

class AddTransactionSheet extends StatefulWidget {
  final bool isEditing;
  final Transaction? existingTransaction;

  const AddTransactionSheet({
    Key? key,
    this.isEditing = false,
    this.existingTransaction,
  }) : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  double _amount = 0.0;
  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _accountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingTransaction != null) {
      final txn = widget.existingTransaction!;
      _amount = txn.amount;
      _type = txn.type;
      _categoryId = txn.categoryId.isNotEmpty ? txn.categoryId : null;
      _accountId = txn.accountId.isNotEmpty ? txn.accountId : null;
      _toAccountId = txn.toAccountId;
      _date = txn.date;
      _noteController.text = txn.note ?? '';
      _isRecurring = txn.isRecurring;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_amount <= 0) return false;
    if (_accountId == null) return false;
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountId == _accountId) return false;
    } else {
      if (_categoryId == null) return false;
    }
    return true;
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppColors.secondarySystemBackground(context),
        child: Column(
          children: [
            Container(
              color: AppColors.tertiarySystemBackground(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _date,
                onDateTimeChanged: (val) {
                  setState(() {
                    _date = val;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker({required bool isSource}) {
    final dataStore = Provider.of<DataStore>(context, listen: false);
    final list = isSource
        ? dataStore.accounts
        : dataStore.accounts.where((a) => a.id != _accountId).toList();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(isSource ? 'Select Account' : 'Select Destination Account'),
        actions: list.map((acc) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (isSource) {
                  _accountId = acc.id;
                  if (_toAccountId == _accountId) {
                    _toAccountId = null;
                  }
                } else {
                  _toAccountId = acc.id;
                }
              });
              Navigator.of(context).pop();
            },
            child: Text(acc.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showFrequencyPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppColors.secondarySystemBackground(context),
        child: Column(
          children: [
            Container(
              color: AppColors.tertiarySystemBackground(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _recurringFrequency = RecurringFrequency.values[index];
                  });
                },
                children: RecurringFrequency.values.map((f) => Center(child: Text(f.label))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_isValid) return;

    final dataStore = Provider.of<DataStore>(context, listen: false);
    final note = _noteController.text.trim();
    
    final newTxn = Transaction(
      id: widget.existingTransaction?.id,
      amount: _amount,
      type: _type,
      categoryId: _type == TransactionType.transfer ? '' : (_categoryId ?? ''),
      accountId: _accountId ?? '',
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      date: _date,
      note: note.isEmpty ? null : note,
      isRecurring: _isRecurring,
      recurringId: widget.existingTransaction?.recurringId,
    );

    try {
      if (widget.isEditing && widget.existingTransaction != null) {
        await dataStore.updateTransaction(
          oldTx: widget.existingTransaction!,
          newTx: newTxn,
        );
      } else {
        await dataStore.addTransaction(newTxn);

        if (_isRecurring) {
          final rule = RecurringRule(
            title: note.isEmpty ? 'Recurring ${_type.label}' : note,
            amount: _amount,
            type: _type,
            categoryId: _type == TransactionType.transfer ? '' : (_categoryId ?? ''),
            accountId: _accountId ?? '',
            frequency: _recurringFrequency,
            startDate: _date,
            nextDueDate: RecurringService.advanceDate(_date, _recurringFrequency),
            isActive: true,
          );
          await dataStore.addRecurringRule(rule);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error Saving'),
          content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;

    final categories = dataStore.categories
        .where((c) => c.type.label == _type.label)
        .toList();

    final accountName = _accountId != null
        ? dataStore.accounts.firstWhere((a) => a.id == _accountId, orElse: () => Account(id: '', name: 'Select Account', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now())).name
        : 'Select Account';

    final toAccountName = _toAccountId != null
        ? dataStore.accounts.firstWhere((a) => a.id == _toAccountId, orElse: () => Account(id: '', name: 'Select Account', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now())).name
        : 'Select Account';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          widget.isEditing ? 'Edit Transaction' : 'New Transaction',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isValid ? _save : null,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AmountTextField(
                    value: _amount,
                    currencySymbol: currencySymbol,
                    onChanged: (val) {
                      setState(() {
                        _amount = val;
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<TransactionType>(
                      groupValue: _type,
                      onValueChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _type = val;
                            _categoryId = null;
                          });
                        }
                      },
                      children: {
                        TransactionType.expense: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Expense'),
                        ),
                        TransactionType.income: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Income'),
                        ),
                        TransactionType.transfer: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Transfer'),
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('DETAILS'),
              children: [
                if (_type != TransactionType.transfer)
                  CupertinoListTile(
                    title: const Text('Category'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CategoryPicker(
                        categories: categories,
                        selectedCategoryId: _categoryId,
                        onCategorySelected: (catId) {
                          setState(() {
                            _categoryId = catId;
                          });
                        },
                      ),
                    ),
                  ),
                CupertinoListTile(
                  title: Text(_type == TransactionType.transfer ? 'From Account' : 'Account'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(accountName),
                  onTap: () => _showAccountPicker(isSource: true),
                ),
                if (_type == TransactionType.transfer)
                  CupertinoListTile(
                    title: const Text('To Account'),
                    trailing: const CupertinoListTileChevron(),
                    additionalInfo: Text(toAccountName),
                    onTap: () => _showAccountPicker(isSource: false),
                  ),
                CupertinoListTile(
                  title: const Text('Date'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(
                    DateFormat.yMMMMd().add_jm().format(_date),
                  ),
                  onTap: _showDatePicker,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('NOTE'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _noteController,
                  placeholder: 'Optional note',
                  prefix: const Icon(
                    CupertinoIcons.pencil,
                    color: CupertinoColors.systemGrey,
                  ),
                  decoration: null,
                ),
              ],
            ),
            if (!widget.isEditing)
              CupertinoListSection.insetGrouped(
                children: [
                  CupertinoListTile(
                    title: const Text('Make Recurring'),
                    trailing: CupertinoSwitch(
                      value: _isRecurring,
                      onChanged: (val) {
                        setState(() {
                          _isRecurring = val;
                        });
                      },
                    ),
                  ),
                  if (_isRecurring)
                    CupertinoListTile(
                      title: const Text('Frequency'),
                      trailing: const CupertinoListTileChevron(),
                      additionalInfo: Text(_recurringFrequency.label),
                      onTap: _showFrequencyPicker,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
