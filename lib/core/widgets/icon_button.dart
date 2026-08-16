import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }
}
