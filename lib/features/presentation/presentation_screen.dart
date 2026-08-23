import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/presentation_document.dart';
import 'widgets/presentation_canvas.dart';
import '../ai/widgets/ai_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'widgets/presentation_toolbar.dart';
import 'widgets/slide_sorter.dart';
import '../../core/widgets/bottom_sheet.dart';
import 'slideshow_screen.dart';

class PresentationScreen extends StatefulWidget {
  final String documentId;

  const PresentationScreen({super.key, required this.documentId});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  PresentationDocument? _document;
  bool _isLoading = true;
  String? _selectedElementId;

  final ValueNotifier<String> _saveStatus = ValueNotifier<String>('Saved');
  Timer? _debounceTimer;

  final List<PresentationDocument> _undoStack = [];
  final List<PresentationDocument> _redoStack = [];

  void _commitHistory() {
    if (_document == null) return;
    // Cap history size to prevent memory leaks
    if (_undoStack.length >= 20) {
      _undoStack.removeAt(0);
    }
    // Deep copy document to history
    final jsonStr = jsonEncode(_document!.toJson());
    final copy = PresentationDocument.fromJson(jsonDecode(jsonStr));
    _undoStack.add(copy);
    _redoStack.clear(); // Any new action invalidates redo stack
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    // Save current state to redo
    final jsonStr = jsonEncode(_document!.toJson());
    final copy = PresentationDocument.fromJson(jsonDecode(jsonStr));
    _redoStack.add(copy);

    setState(() {
      _document = _undoStack.removeLast();
    });
    _onDocumentChanged();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    // Save current state to undo
    final jsonStr = jsonEncode(_document!.toJson());
    final copy = PresentationDocument.fromJson(jsonDecode(jsonStr));
    _undoStack.add(copy);

    setState(() {
      _document = _redoStack.removeLast();
    });
    _onDocumentChanged();
  }

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _storage.getPresentation(widget.documentId);
    if (mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _onDocumentChanged() {
    _saveStatus.value = 'Saving...';
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveDocument();
    });
  }

  Future<void> _saveDocument() async {
    if (_document == null) return;
    try {
      final updatedDoc = _document!.copyWith(PresentationDocumentOptions(updatedAt: DateTime.now()));
      await _storage.updatePresentation(updatedDoc);
      _document = updatedDoc;
      _saveStatus.value = 'Saved';
    } catch (e) {
      _saveStatus.value = 'Save failed';
    }
  }

  void _handleElementSelected(String elementId) {
    setState(() {
      _selectedElementId = elementId.isEmpty ? null : elementId;
    });
  }

  void _handleElementDragged(String elementId, double dx, double dy) {
    if (_document == null) return;

    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == elementId);

    setState(() {
      element.x += dx;
      element.y += dy;
    });

    _onDocumentChanged();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Presentation not found')),
      );
    }

    final activeSlide = _document!.slides.firstWhere(
      (s) => s.id == _document!.activeSlide,
      orElse: () => _document!.slides.first,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(_document!.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ValueListenableBuilder<String>(
                valueListenable: _saveStatus,
                builder: (context, status, child) {
                  return Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: status == 'Save failed'
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outline,
                        ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => SlideshowScreen(document: _document!),
                 ),
               );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          PresentationToolbar(
            onAiPressed: _openAIBottomSheet,
            onAddText: _addTextElement,
            onAddImage: _addImageElement,
            onBringForward: _bringForward,
            onSendBackward: _sendBackward,
            onDeleteElement: _deleteSelectedElement,
            hasSelection: _selectedElementId != null,
            currentStyle: _selectedElementId != null ?
              activeSlide.elements.firstWhere((e) => e.id == _selectedElementId).style : {},
            onStyleChanged: _applyFormatting,
            onUndo: _undo,
            onRedo: _redo,
            canUndo: _undoStack.isNotEmpty,
            canRedo: _redoStack.isNotEmpty,
          ),
          Expanded(
            child: PresentationCanvas(
              slide: activeSlide,
              selectedElementId: _selectedElementId,
              onElementSelected: _handleElementSelected,
              onElementDragged: _handleElementDragged,
              onDragEnd: _commitHistory,
              onElementResized: _handleElementResized,
              onResizeEnd: _commitHistory,
              onElementContentChanged: _handleElementContentChanged,
            ),
          ),
          SlideSorter(
            document: _document!,
            onSlideSelected: _switchSlide,
            onAddSlide: _addSlide,
            onSlideOptions: _showSlideOptions,
          ),
        ],
      ),
    );
  }

  void _openAIBottomSheet() {
    String? contextText;
    if (_selectedElementId != null && _document != null) {
      final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
      try {
        final element = slide.elements.firstWhere((e) => e.id == _selectedElementId);
        if (element.type == 'text') {
           contextText = 'Slide Text Context: ${element.content}';
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AIBottomSheet(
          contextText: contextText,
          onInsertText: (text) {
             _commitHistory();
             if (_document == null) return;
             final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);

             final newElement = SlideElement(
               id: const Uuid().v4(),
               type: 'text',
               x: 100,
               y: 100,
               width: 400,
               height: 200,
               content: text,
               style: {'fontSize': 32.0, 'color': '#000000'},
               zIndex: slide.elements.length,
             );

             setState(() {
               slide.elements.add(newElement);
               _selectedElementId = newElement.id;
             });
             _onDocumentChanged();
          },
          onReplaceText: contextText != null ? (text) {
             _commitHistory();
             if (_document == null || _selectedElementId == null) return;
             final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
             final element = slide.elements.firstWhere((e) => e.id == _selectedElementId);

             setState(() {
                element.content = text;
             });
             _onDocumentChanged();
          } : null,
        ),
      ),
    );
  }

  void _addTextElement() {
    _commitHistory();
    if (_document == null) return;
    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);

    final newElement = SlideElement(
      id: const Uuid().v4(),
      type: 'text',
      x: 100,
      y: 100,
      width: 400,
      height: 100,
      content: 'New Text',
      style: {'fontSize': 32.0, 'color': '#000000'},
      zIndex: slide.elements.length,
    );

    setState(() {
      slide.elements.add(newElement);
      _selectedElementId = newElement.id;
    });
    _onDocumentChanged();
  }

  Future<void> _addImageElement() async {
    _commitHistory();
    if (_document == null) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final savedPath = await _storage.saveImage(_document!.id, image.path);
        final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);

        final newElement = SlideElement(
          id: const Uuid().v4(),
          type: 'image',
          x: 100,
          y: 100,
          width: 300,
          height: 300,
          content: savedPath,
          style: {},
          zIndex: slide.elements.length,
        );

        setState(() {
          slide.elements.add(newElement);
          _selectedElementId = newElement.id;
        });
        _onDocumentChanged();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add image')));
      }
    }
  }

  void _deleteSelectedElement() {
    _commitHistory();
    if (_document == null || _selectedElementId == null) return;
    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);

    setState(() {
      slide.elements.removeWhere((e) => e.id == _selectedElementId);
      _selectedElementId = null;
    });
    _onDocumentChanged();
  }

  void _bringForward() {
    _commitHistory();
    if (_document == null || _selectedElementId == null) return;
    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == _selectedElementId);

    setState(() {
      element.zIndex += 1;
    });
    _onDocumentChanged();
  }

  void _sendBackward() {
    _commitHistory();
    if (_document == null || _selectedElementId == null) return;
    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == _selectedElementId);

    setState(() {
      element.zIndex -= 1;
    });
    _onDocumentChanged();
  }

  void _addSlide() {
    _commitHistory();
    if (_document == null) return;
    final newId = const Uuid().v4();
    final newSlide = SlideData(
      id: newId,
      name: 'Slide ${_document!.slides.length + 1}',
      elements: [],
    );
    setState(() {
      _document!.slides.add(newSlide);
      _document!.activeSlide = newId;
      _selectedElementId = null;
    });
    _onDocumentChanged();
  }

  void _switchSlide(String slideId) {
    if (_document == null) return;
    setState(() {
      _document!.activeSlide = slideId;
      _selectedElementId = null;
    });
    _onDocumentChanged();
  }

  void _deleteSlide(String slideId) {
    _commitHistory();
    if (_document == null) return;
    if (_document!.slides.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete the last slide')));
      return;
    }
    setState(() {
      _document!.slides.removeWhere((s) => s.id == slideId);
      if (_document!.activeSlide == slideId) {
        _document!.activeSlide = _document!.slides.first.id;
      }
      _selectedElementId = null;
    });
    _onDocumentChanged();
  }

  void _showSlideOptions(String slideId) {
    showAppBottomSheet(
      context: context,
      title: 'Slide Options',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Slide', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteSlide(slideId);
            },
          ),
        ],
      ),
    );
  }

  void _handleElementResized(String elementId, double dx, double dy) {
    if (_document == null) return;

    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == elementId);

    setState(() {
      element.width += dx;
      if (element.width < 50) element.width = 50;
      element.height += dy;
      if (element.height < 50) element.height = 50;
    });

    _onDocumentChanged();
  }

  void _handleElementContentChanged(String elementId, String newContent) {
    if (_document == null) return;

    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == elementId);

    element.content = newContent;

    _onDocumentChanged();
  }

  void _applyFormatting(String key, dynamic value) {
    _commitHistory();
    if (_document == null || _selectedElementId == null) return;

    final slide = _document!.slides.firstWhere((s) => s.id == _document!.activeSlide);
    final element = slide.elements.firstWhere((e) => e.id == _selectedElementId);

    setState(() {
      if (value == null || value == false) {
         element.style.remove(key);
      } else {
         element.style[key] = value;
      }
    });

    _onDocumentChanged();
  }
}
