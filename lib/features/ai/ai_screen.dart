import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'AI Assistant'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(
              'AI Features Coming Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Generate documents, summarize text, and more.'),
          ],
        ),
      ),
    );
  }
}
