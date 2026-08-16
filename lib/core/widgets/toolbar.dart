import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  final List<Widget> children;

  const Toolbar({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: child,
          )).toList(),
        ),
      ),
    );
  }
}
