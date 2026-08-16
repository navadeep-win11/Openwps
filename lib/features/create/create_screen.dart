import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  bool _isCreating = false;

  Future<void> _createWriterDocument() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final doc = await _storage.createDocument('Untitled Document');
      if (mounted) {
        Navigator.pushNamed(context, '/writer', arguments: doc.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create document')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create New'),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: 'Document',
                  icon: Icons.description,
                  onPressed: _createWriterDocument,
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
          if (_isCreating)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
