import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/empty_state_view.dart';
import '../../components/app_colors.dart';
import 'add_category_sheet.dart';

class CategoryListView extends StatefulWidget {
  const CategoryListView({Key? key}) : super(key: key);

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  void _openAddCategory() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddCategorySheet(),
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, DataStore dataStore, Category category) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will also delete any budget limits set for this category.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true && category.id != null) {
      try {
        await dataStore.deleteCategory(category.id!);
      } catch (e) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Cannot Delete'),
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
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final expenses = dataStore.categories.where((c) => c.type == CategoryType.expense).toList();
    final income = dataStore.categories.where((c) => c.type == CategoryType.income).toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Categories',
          style: TextStyle(color: AppColors.label(context)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.plus),
          onPressed: _openAddCategory,
        ),
        border: null,
      ),
      child: SafeArea(
        child: dataStore.categories.isEmpty
            ? const Center(
                child: EmptyStateView(
                  icon: CupertinoIcons.tag_fill,
                  title: 'No Categories',
                  subtitle: 'Add your first category to start organizing.',
                ),
              )
            : ListView(
                children: [
                  if (expenses.isNotEmpty)
                    CupertinoListSection.insetGrouped(
                      header: const Text('EXPENSES'),
                      children: expenses.map((cat) => _buildCategoryTile(context, dataStore, cat)).toList(),
                    ),
                  if (income.isNotEmpty)
                    CupertinoListSection.insetGrouped(
                      header: const Text('INCOME'),
                      children: income.map((cat) => _buildCategoryTile(context, dataStore, cat)).toList(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, DataStore dataStore, Category category) {
    final Color catColor = AppColors.hexToColor(category.color);
    
    return Dismissible(
      key: Key(category.id ?? ''),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        await _deleteCategory(context, dataStore, category);
        return false; // manual handling
      },
      background: Container(
        color: CupertinoColors.systemRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
        ),
      ),
      child: CupertinoListTile(
        title: Text(
          category.name,
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: _buildIcon(category, catColor),
        ),
      ),
    );
  }

  Widget _buildIcon(Category category, Color catColor) {
    final bool isEmoji = category.icon.runes.any((r) => r > 127);
    if (isEmoji) {
      return Text(
        category.icon,
        style: const TextStyle(fontSize: 20),
      );
    }
    return Icon(
      AppColors.getCupertinoIcon(category.icon),
      color: catColor,
      size: 20,
    );
  }
}
