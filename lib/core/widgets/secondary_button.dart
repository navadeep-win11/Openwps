import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isFullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: _style(context),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: _style(context),
            child: Text(label),
          );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }

  ButtonStyle _style(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      minimumSize: const Size(double.infinity, 48),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }
}
