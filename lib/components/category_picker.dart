import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import 'app_colors.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryPicker({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onCategorySelected(category.id),
              child: CategoryCell(
                category: category,
                isSelected: isSelected,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryCell extends StatelessWidget {
  final Category category;
  final bool isSelected;

  const CategoryCell({
    Key? key,
    required this.category,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.hexToColor(category.color);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? catColor : catColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: _buildIcon(catColor),
        ),
        const SizedBox(height: 8),
        Text(
          category.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppColors.label(context)
                : AppColors.secondaryLabel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(Color catColor) {
    final bool isEmoji = category.icon.runes.any((r) => r > 127);
    if (isEmoji) {
      return Text(
        category.icon,
        style: const TextStyle(fontSize: 24),
      );
    }
    IconData iconData = CupertinoIcons.question;
    switch (category.icon) {
      case 'banknote':
      case 'banknote.fill':
        iconData = CupertinoIcons.money_dollar_circle;
        break;
      case 'building.columns':
      case 'building.columns.fill':
        iconData = CupertinoIcons.house_alt;
        break;
      case 'creditcard':
      case 'creditcard.fill':
        iconData = CupertinoIcons.creditcard;
        break;
      case 'chart.line.uptrend.xyaxis':
        iconData = CupertinoIcons.graph_square;
        break;
      case 'gear':
        iconData = CupertinoIcons.settings;
        break;
      case 'house':
      case 'house.fill':
        iconData = CupertinoIcons.home;
        break;
      case 'tag':
      case 'tag.fill':
        iconData = CupertinoIcons.tag;
        break;
    }
    return Icon(
      iconData,
      color: isSelected ? CupertinoColors.white : catColor,
      size: 24,
    );
  }
}
