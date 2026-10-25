import 'package:flutter/material.dart';

import '../theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Text(text, style: TextStyle(fontSize: 12, color: subColor(context))),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN || value.isInfinite ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: isDark(context) ? const Color(0xFF2A2F36) : const Color(0xFFEFF4F0),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: Container(color: color),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.text,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(text, style: TextStyle(fontSize: 13, color: subColor(context))),
          if (actionText != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(actionText!, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  const Dot(this.color, {super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确认',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text(message, style: TextStyle(fontSize: 13, color: subColor(ctx), height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('取消', style: TextStyle(fontSize: 13, color: subColor(ctx))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText,
            style: TextStyle(fontSize: 13, color: danger ? AppColors.red : AppColors.primary),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A3A31),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}
