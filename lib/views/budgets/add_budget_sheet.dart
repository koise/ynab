import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/amount_text_field.dart';
import '../../components/app_colors.dart';

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({Key? key}) : super(key: key);

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  double _limit = 0.0;
  String _categoryId = '';
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isValid => _categoryId.isNotEmpty && _limit > 0;

  void _showCategoryPicker(List<Category> categories) {
    if (categories.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Category'),
        actions: categories.map((cat) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _categoryId = cat.id ?? '';
              });
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.icon),
                const SizedBox(width: 8),
                Text(cat.name),
              ],
            ),
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

  void _showPeriodPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Period'),
        actions: BudgetPeriod.values.map((p) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _period = p;
              });
              Navigator.of(context).pop();
            },
            child: Text(p.label),
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

  Future<void> _saveBudget() async {
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final dataStore = Provider.of<DataStore>(context, listen: false);

    final budget = Budget(
      categoryId: _categoryId,
      limit: _limit,
      period: _period,
      createdAt: DateTime.now(),
    );

    try {
      await dataStore.addBudget(budget);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;

    final budgetedCategoryIds = dataStore.budgets.map((b) => b.categoryId).toSet();
    final availableCategories = dataStore.categories
        .where((c) => c.type == CategoryType.expense && !budgetedCategoryIds.contains(c.id ?? ''))
        .toList();

    final selectedCategory = _categoryId.isNotEmpty
        ? dataStore.categories.firstWhere((c) => c.id == _categoryId, orElse: () => const Category(id: '', name: '', icon: '', color: '', type: CategoryType.expense))
        : null;

    final categoryLabel = selectedCategory != null
        ? '${selectedCategory.icon} ${selectedCategory.name}'
        : 'Select Category';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'New Budget',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isValid && !_isSaving ? _saveBudget : null,
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
                    value: _limit,
                    currencySymbol: currencySymbol,
                    onChanged: (val) {
                      setState(() {
                        _limit = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text('Category'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(categoryLabel),
                  onTap: availableCategories.isEmpty
                      ? null
                      : () => _showCategoryPicker(availableCategories),
                ),
                if (availableCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'All expense categories already have a budget.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryLabel(context),
                      ),
                    ),
                  ),
                CupertinoListTile(
                  title: const Text('Period'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(_period.label),
                  onTap: _showPeriodPicker,
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
