import 'package:flutter/material.dart';

class FormulaBar extends StatelessWidget {
  final String selectedCellPosition;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final VoidCallback onFocusGained;

  const FormulaBar({
    super.key,
    required this.selectedCellPosition,
    required this.textController,
    required this.focusNode,
    required this.onSubmitted,
    required this.onFocusGained,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              selectedCellPosition.isEmpty ? '-' : selectedCellPosition,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.functions, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) onFocusGained();
              },
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  hintText: 'Enter text or formula',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: (_) => onSubmitted(),
                textInputAction: TextInputAction.done,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: onSubmitted,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
