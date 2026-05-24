import 'package:flutter/cupertino.dart';

class AppColors {
  static const Color primary = CupertinoColors.systemBlue;
  static const Color accent = CupertinoColors.systemPurple;
  
  static const Color income = CupertinoColors.systemGreen;
  static const Color expense = CupertinoColors.systemRed;
  static const Color transfer = CupertinoColors.systemBlue;

  static Color systemBackground(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0B0F)
        : const Color(0xFFF5F6FA);
  }

  static Color secondarySystemBackground(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF161622)
        : const Color(0xFFFFFFFF);
  }

  static Color tertiarySystemBackground(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222233)
        : const Color(0xFFEEF0F6);
  }

  static Color borderColor(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF28283C)
        : const Color(0xFFE8ECF5);
  }

  static LinearGradient brandGradient = const LinearGradient(
    colors: [Color(0xFF5B6CF6), Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color label(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? CupertinoColors.white
        : const Color(0xFF1C1C1E);
  }

  static Color secondaryLabel(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF636366);
  }

  static Color hexToColor(String hex) {
    String hexSanitized = hex.trim().replaceAll('#', '');
    if (hexSanitized.length == 6) {
      hexSanitized = 'FF$hexSanitized';
    }
    return Color(int.parse(hexSanitized, radix: 16));
  }

  static IconData getCupertinoIcon(String name) {
    switch (name) {
      case 'cart.fill':
        return CupertinoIcons.cart_fill;
      case 'fork.knife':
        return CupertinoIcons.capsule;
      case 'bus.fill':
        return CupertinoIcons.bus;
      case 'house.fill':
        return CupertinoIcons.house_fill;
      case 'cross.case.fill':
        return CupertinoIcons.heart_fill;
      case 'gamecontroller.fill':
        return CupertinoIcons.gamecontroller_fill;
      case 'bag.fill':
        return CupertinoIcons.bag_fill;
      case 'book.fill':
        return CupertinoIcons.book_fill;
      case 'airplane':
        return CupertinoIcons.airplane;
      case 'car.fill':
        return CupertinoIcons.car_fill;
      case 'tv.fill':
        return CupertinoIcons.tv_fill;
      case 'gift.fill':
        return CupertinoIcons.gift_fill;
      case 'briefcase.fill':
        return CupertinoIcons.briefcase_fill;
      case 'dollarsign.circle.fill':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'chart.line.uptrend.xyaxis':
        return CupertinoIcons.graph_square_fill;
      case 'banknote':
      case 'banknote.fill':
        return CupertinoIcons.money_dollar;
      case 'square.grid.2x2.fill':
        return CupertinoIcons.square_grid_2x2_fill;
      case 'heart.fill':
        return CupertinoIcons.heart_fill;
      case 'pawprint.fill':
        return CupertinoIcons.paw;
      case 'leaf.fill':
        return CupertinoIcons.leaf_arrow_circlepath;
      case 'flame.fill':
        return CupertinoIcons.flame_fill;
      case 'drop.fill':
        return CupertinoIcons.drop_fill;
      case 'bolt.fill':
        return CupertinoIcons.bolt_fill;
      case 'building.columns':
      case 'building.columns.fill':
        return CupertinoIcons.house_alt;
      case 'creditcard':
      case 'creditcard.fill':
        return CupertinoIcons.creditcard;
      case 'gear':
        return CupertinoIcons.settings;
      case 'tag':
      case 'tag.fill':
        return CupertinoIcons.tag;
      default:
        return CupertinoIcons.question;
    }
  }
}
