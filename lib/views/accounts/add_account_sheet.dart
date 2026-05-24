import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/amount_text_field.dart';
import '../../components/app_colors.dart';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({Key? key}) : super(key: key);

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final TextEditingController _nameController = TextEditingController();
  AccountType _type = AccountType.cash;
  double _balance = 0.0;
  String _currency = '';
  String _selectedColor = '#2196F3';
  bool _isSaving = false;

  final List<String> _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
    '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataStore = Provider.of<DataStore>(context, listen: false);
      setState(() {
        _currency = dataStore.userSettings.currencySymbol;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  void _showTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Account Type'),
        actions: AccountType.values.map((type) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _type = type;
              });
              Navigator.of(context).pop();
            },
            child: Text(type.label),
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

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
    });

    final dataStore = Provider.of<DataStore>(context, listen: false);
    final account = Account(
      name: _nameController.text.trim(),
      type: _type,
      balance: _balance,
      currency: _currency.isNotEmpty ? _currency : '₱',
      color: _selectedColor,
      createdAt: DateTime.now(),
    );

    try {
      await dataStore.addAccount(account);
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
          'New Account',
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
                  placeholder: 'Account Name',
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                CupertinoListTile(
                  title: const Text('Type'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(_type.label),
                  onTap: _showTypePicker,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AmountTextField(
                    value: _balance,
                    currencySymbol: _currency.isNotEmpty ? _currency : '₱',
                    onChanged: (val) {
                      setState(() {
                        _balance = val;
                      });
                    },
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
