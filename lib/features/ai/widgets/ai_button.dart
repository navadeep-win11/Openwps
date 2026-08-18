import 'package:flutter/material.dart';

class AIButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AIButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
      tooltip: 'AI Assistant',
      onPressed: onPressed,
    );
  }
}
