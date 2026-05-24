import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateView({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container with gradient bg
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A2A3E), const Color(0xFF1E1E2E)]
                      : [const Color(0xFFEEF0FF), const Color(0xFFF5F0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3A3A50)
                      : const Color(0xFFDDDEFF),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark
                    ? const Color(0xFF7B7FD4)
                    : const Color(0xFF5B6CF6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.label(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.secondaryLabel(context),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
