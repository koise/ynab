import 'package:flutter/cupertino.dart';

class AppFAB extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? label;

  const AppFAB({
    Key? key,
    required this.onTap,
    this.icon = CupertinoIcons.plus,
    this.label,
  }) : super(key: key);

  @override
  State<AppFAB> createState() => _AppFABState();
}

class _AppFABState extends State<AppFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) async {
    await _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = widget.label != null && widget.label!.isNotEmpty;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          height: 56,
          padding: hasLabel
              ? const EdgeInsets.symmetric(horizontal: 20)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(hasLabel ? 28 : 28),
            gradient: const LinearGradient(
              colors: [Color(0xFF5B6CF6), Color(0xFF9B59B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B6CF6).withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: CupertinoColors.white,
                size: 24,
              ),
              if (hasLabel) ...[
                const SizedBox(width: 8),
                Text(
                  widget.label!,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
