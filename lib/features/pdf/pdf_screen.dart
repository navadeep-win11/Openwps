import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'widgets/pdf_toolbar.dart';

class PdfScreen extends StatefulWidget {
  final String documentId;
  final String filePath;
  final String title;

  const PdfScreen({
    super.key,
    required this.documentId,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  late PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  void _openAIBottomSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF contextual AI selection integration is deferred because the locked pdfrx 2.4.7 API does not expose the required selection functionality.'))
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewer.file(
              widget.filePath,
              controller: _controller,
              params: const PdfViewerParams(),
            ),
          ),
          PdfToolbar(onAiPressed: _openAIBottomSheet),
        ],
      ),
    );
  }
}
