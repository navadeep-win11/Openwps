import 'dart:io';
import 'package:flutter/material.dart';
import '../../../storage/models/presentation_document.dart';

class PresentationElementWidget extends StatefulWidget {
  final SlideElement element;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onResizeStart;
  final Function(DragUpdateDetails) onResizeUpdate;
  final VoidCallback? onResizeEnd;
  final Function(String) onContentChanged;

  const PresentationElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onTap,
    this.onDragStart,
    required this.onDragUpdate,
    this.onDragEnd,
    this.onResizeStart,
    required this.onResizeUpdate,
    this.onResizeEnd,
    required this.onContentChanged,
  });

  @override
  State<PresentationElementWidget> createState() => _PresentationElementWidgetState();
}

class _PresentationElementWidgetState extends State<PresentationElementWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.element.content);
  }

  @override
  void didUpdateWidget(PresentationElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.content != widget.element.content && _textController.text != widget.element.content) {
      _textController.text = widget.element.content;
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;

    if (widget.element.type == 'text') {
      contentWidget = TextField(
        controller: _textController,
        onChanged: widget.onContentChanged,
        style: TextStyle(
          fontSize: widget.element.style['fontSize'] ?? 24.0,
          fontWeight: widget.element.style['bold'] == true ? FontWeight.bold : FontWeight.normal,
          fontStyle: widget.element.style['italic'] == true ? FontStyle.italic : FontStyle.normal,
          decoration: widget.element.style['underline'] == true ? TextDecoration.underline : TextDecoration.none,
          color: widget.element.style['color'] != null
             ? Color(int.parse(widget.element.style['color'].replaceAll('#', '0xFF')))
             : Colors.black,
        ),
        textAlign: _getAlignment(widget.element.style['align']),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        maxLines: null,
      );
    } else if (widget.element.type == 'image') {
      contentWidget = Image.file(
        File(widget.element.content),
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    } else {
      contentWidget = Container(color: Colors.red); // Fallback
    }

    return Positioned(
      left: widget.element.x,
      top: widget.element.y,
      width: widget.element.width,
      height: widget.element.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            onPanStart: widget.isSelected ? (_) => widget.onDragStart?.call() : null,
            onPanUpdate: widget.isSelected ? widget.onDragUpdate : null,
            onPanEnd: widget.isSelected ? (_) => widget.onDragEnd?.call() : null,
            child: Container(
              decoration: BoxDecoration(
                border: widget.isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: contentWidget,
            ),
          ),
          if (widget.isSelected)
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanStart: (_) => widget.onResizeStart?.call(),
                onPanUpdate: widget.onResizeUpdate,
                onPanEnd: (_) => widget.onResizeEnd?.call(),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  TextAlign _getAlignment(String? align) {
    if (align == 'center') return TextAlign.center;
    if (align == 'right') return TextAlign.right;
    return TextAlign.left;
  }
}
