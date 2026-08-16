import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/writer_document.dart';
import 'widgets/writer_toolbar.dart';

class WriterScreen extends StatefulWidget {
  final String documentId;
  const WriterScreen({super.key, required this.documentId});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  final ImagePicker _picker = ImagePicker();
  WriterDocument? _document;
  QuillController? _controller;
  bool _isLoading = true;
  String _saveStatus = 'Saved';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _storage.getDocument(widget.documentId);
    if (doc != null) {
      final documentContent = Document.fromJson(jsonDecode(doc.content));
      setState(() {
        _document = doc;
        _controller = QuillController(
          document: documentContent,
          selection: const TextSelection.collapsed(offset: 0),
        );
        _isLoading = false;
      });

      _controller?.document.changes.listen((_) {
        _onDocumentChanged();
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDocumentChanged() {
    setState(() {
      _saveStatus = 'Saving...';
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveDocument();
    });
  }

  Future<void> _saveDocument() async {
    if (_document == null || _controller == null) return;

    try {
      final String currentContent = jsonEncode(_controller!.document.toDelta().toJson());
      final updatedDoc = _document!.copyWith(content: currentContent);

      await _storage.updateDocument(updatedDoc);

      setState(() {
        _document = updatedDoc;
        _saveStatus = 'Saved';
      });
    } catch (e) {
      setState(() {
        _saveStatus = 'Save failed';
      });
    }
  }

  Future<void> _pickAndInsertImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && _controller != null) {
        final savedPath = await _storage.saveImage(widget.documentId, image.path);

        final index = _controller!.selection.baseOffset;
        final length = _controller!.selection.extentOffset - index;
        _controller!.replaceText(
          index,
          length,
          BlockEmbed.image(savedPath),
          null,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to insert image')),
        );
      }
    }
  }

  Future<void> _exportToTxt() async {
    if (_controller == null || _document == null) return;

    try {
      final plainText = _controller!.document.toPlainText();
      final dir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${dir.path}/exports');
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      final file = File('${exportsDir.path}/${_document!.title}.txt');
      await file.writeAsString(plainText);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported successfully to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed')),
        );
      }
    }
  }

  void _showInsertMenu(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Insert',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Image'),
            onTap: () {
              Navigator.pop(context);
              _pickAndInsertImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Table (Coming Soon)'),
            enabled: false,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Link (Coming Soon)'),
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'More Options',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export to TXT'),
            onTap: () {
              Navigator.pop(context);
              _exportToTxt();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _saveStatus,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _saveStatus == 'Save failed'
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showInsertMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuillEditor.basic(
                controller: _controller!,
              ),
            ),
          ),
          WriterToolbar(controller: _controller!),
        ],
      ),
    );
  }
}
