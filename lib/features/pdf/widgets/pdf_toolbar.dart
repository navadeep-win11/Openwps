import 'package:flutter/material.dart';
import '../../ai/widgets/ai_button.dart';

class PdfToolbar extends StatelessWidget {
  final VoidCallback onAiPressed;

  const PdfToolbar({super.key, required this.onAiPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              AIButton(onPressed: onAiPressed),
            ],
          ),
        ),
      ),
    );
  }
}
