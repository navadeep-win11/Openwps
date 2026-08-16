import 'package:flutter/material.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      content: content,
      actions: actions,
    ),
  );
}

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    );
  }
}
