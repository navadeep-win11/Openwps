import 'package:flutter/material.dart';

enum BadgeStatus {
  success,
  warning,
  error,
  info,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.success:
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case BadgeStatus.warning:
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case BadgeStatus.error:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      case BadgeStatus.info:
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
