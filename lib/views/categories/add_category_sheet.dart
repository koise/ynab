import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/app_colors.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({Key? key}) : super(key: key);

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  CategoryType _type = CategoryType.expense;
  String _selectedIcon = 'cart.fill';
  String _selectedColor = '#FF9800';
  bool _isSaving = false;

  final List<String> _icons = [
    'cart.fill', 'fork.knife', 'bus.fill', 'house.fill', 'cross.case.fill',
    'gamecontroller.fill', 'bag.fill', 'book.fill', 'airplane', 'car.fill',
    'tv.fill', 'gift.fill', 'briefcase.fill', 'dollarsign.circle.fill',
    'chart.line.uptrend.xyaxis', 'banknote.fill', 'square.grid.2x2.fill',
    'heart.fill', 'pawprint.fill', 'leaf.fill', 'flame.fill', 'drop.fill', 'bolt.fill'
  ];

  final List<String> _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
    '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
    });

    final dataStore = Provider.of<DataStore>(context, listen: false);
    final category = Category(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      type: _type,
    );

    try {
      await dataStore.addCategory(category);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error Saving'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'New Category',
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
                  controller: _nameController,
                  placeholder: 'Category Name',
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<CategoryType>(
                      groupValue: _type,
                      onValueChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _type = val;
                          });
                        }
                      },
                      children: {
                        CategoryType.expense: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Expense'),
                        ),
                        CategoryType.income: const Padding(
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
              header: const Text('ICON'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _icons.map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? CupertinoColors.activeBlue.withOpacity(0.2)
                                : CupertinoColors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            AppColors.getCupertinoIcon(icon),
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : (isDark ? CupertinoColors.white : CupertinoColors.black),
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('COLOR'),
              children: [
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final hex = _colors[index];
                      final isSelected = _selectedColor == hex;
                      final color = AppColors.hexToColor(hex);

                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = hex;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                    : CupertinoColors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
