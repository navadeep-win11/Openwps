import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create New'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: 'Document',
              icon: Icons.description,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Spreadsheet',
              icon: Icons.table_chart,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Presentation',
              icon: Icons.slideshow,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'From Template',
              icon: Icons.dashboard_customize,
              onPressed: () => Navigator.pushNamed(context, '/templates'),
            ),
          ],
        ),
      ),
    );
  }
}
