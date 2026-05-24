import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/amount_text_field.dart';
import '../../components/category_picker.dart';
import '../../components/app_colors.dart';

class AddRecurringSheet extends StatefulWidget {
  const AddRecurringSheet({Key? key}) : super(key: key);

  @override
  State<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<AddRecurringSheet> {
  final TextEditingController _titleController = TextEditingController();
  double _amount = 0.0;
  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _accountId;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
        _amount > 0 &&
        _categoryId != null &&
        _accountId != null;
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
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _startDate,
                onDateTimeChanged: (val) {
                  setState(() {
                    _startDate = val;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker() {
    final dataStore = Provider.of<DataStore>(context, listen: false);
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Account'),
        actions: dataStore.accounts.map((acc) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _accountId = acc.id;
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
                    _frequency = RecurringFrequency.values[index];
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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final dataStore = Provider.of<DataStore>(context, listen: false);
    final rule = RecurringRule(
      title: _titleController.text.trim(),
      amount: _amount,
      type: _type,
      categoryId: _categoryId ?? '',
      accountId: _accountId ?? '',
      frequency: _frequency,
      startDate: _startDate,
      nextDueDate: _startDate,
      isActive: true,
    );

    try {
      await dataStore.addRecurringRule(rule);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;

    final categories = dataStore.categories
        .where((c) => c.type.label == _type.label)
        .toList();

    final accountLabel = _accountId != null
        ? dataStore.accounts.firstWhere((a) => a.id == _accountId, orElse: () => Account(id: '', name: 'Select Account', type: AccountType.cash, balance: 0.0, currency: '', color: '', createdAt: DateTime.now())).name
        : 'Select Account';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'New Recurring',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isValid && !_isSaving ? _save : null,
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
                CupertinoTextFormFieldRow(
                  controller: _titleController,
                  placeholder: 'Title (e.g. Netflix, Salary)',
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
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
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<TransactionType>(
                      groupValue: _type,
                      onValueChanged: (val) {
                        if (val != null && val != TransactionType.transfer) {
                          setState(() {
                            _type = val;
                            _categoryId = null;
                          });
                        }
                      },
                      children: const {
                        TransactionType.expense: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Expense'),
                        ),
                        TransactionType.income: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Income'),
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
                  title: const Text('Account'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(accountLabel),
                  onTap: _showAccountPicker,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text('Frequency'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(_frequency.label),
                  onTap: _showFrequencyPicker,
                ),
                CupertinoListTile(
                  title: const Text('Start Date'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(
                    DateFormat.yMMMMd().format(_startDate),
                  ),
                  onTap: _showDatePicker,
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
