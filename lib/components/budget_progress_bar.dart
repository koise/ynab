import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import 'app_colors.dart';

class BudgetProgressBar extends StatefulWidget {
  final BudgetProgress progress;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String currencySymbol;

  const BudgetProgressBar({
    Key? key,
    required this.progress,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  State<BudgetProgressBar> createState() => _BudgetProgressBarState();
}

class _BudgetProgressBarState extends State<BudgetProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress.percentUsed).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BudgetProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.percentUsed != widget.progress.percentUsed) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.percentUsed,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _progressColor {
    final pct = widget.progress.percentUsed;
    if (pct < 0.5) {
      return CupertinoColors.systemGreen;
    } else if (pct < 0.75) {
      return CupertinoColors.systemYellow;
    } else if (pct <= 1.0) {
      return CupertinoColors.systemOrange;
    } else {
      return CupertinoColors.systemRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final catColor = AppColors.hexToColor(widget.categoryColor);

    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
                child: _buildIcon(),
              ),
              const SizedBox(width: 12),
              Text(
                widget.categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.label(context),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.currencySymbol}${widget.progress.budget.limit.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Capsule bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.tertiarySystemBackground(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final pct = _animation.value;
                      final width = constraints.maxWidth * pct;
                      return Container(
                        height: 12,
                        width: pct > 1.0 ? constraints.maxWidth : width.clamp(0.0, constraints.maxWidth),
                        decoration: BoxDecoration(
                          color: _progressColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.currencySymbol}${widget.progress.spent.toStringAsFixed(2)} spent',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryLabel(context),
                ),
              ),
              if (widget.progress.isOverBudget)
                Text(
                  'Overspent by ${widget.currencySymbol}${(widget.progress.spent - widget.progress.budget.limit).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  '${widget.currencySymbol}${widget.progress.remaining.toStringAsFixed(2)} left',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final bool isEmoji = widget.categoryIcon.runes.any((r) => r > 127);
    if (isEmoji) {
      return Text(
        widget.categoryIcon,
        style: const TextStyle(fontSize: 16),
      );
    }
    return Icon(
      AppColors.getCupertinoIcon(widget.categoryIcon),
      color: CupertinoColors.white,
      size: 16,
    );
  }
}
