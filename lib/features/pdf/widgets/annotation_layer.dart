import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import '../../../storage/models/pdf_document.dart' as model;

class AnnotationLayer extends StatefulWidget {
  final model.PdfDocument document;
  final int pageNumber;
  final model.PdfAnnotationType? currentTool;
  final Color currentColor;
  final Function(model.PdfAnnotation) onAnnotationAdded;
  final Function(String) onAnnotationRemoved;
  final PdfViewerController pdfController;

  const AnnotationLayer({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.currentTool,
    required this.currentColor,
    required this.onAnnotationAdded,
    required this.onAnnotationRemoved,
    required this.pdfController,
  });

  @override
  State<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends State<AnnotationLayer> {
  List<Offset> _currentPath = [];
  final Uuid _uuid = const Uuid();

  void _handlePanStart(DragStartDetails details) {
    if (widget.currentTool == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    if (widget.currentTool == model.PdfAnnotationType.pen || widget.currentTool == model.PdfAnnotationType.highlight) {
      setState(() {
        _currentPath = [localPosition];
      });
    } else if (widget.currentTool == model.PdfAnnotationType.note) {
        _showNoteDialog(localPosition);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.currentTool == null || (widget.currentTool != model.PdfAnnotationType.pen && widget.currentTool != model.PdfAnnotationType.highlight)) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _currentPath.add(localPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.currentTool == null || _currentPath.isEmpty) return;
    if (widget.currentTool == model.PdfAnnotationType.pen || widget.currentTool == model.PdfAnnotationType.highlight) {

      // Serialize path points
      final pathData = _currentPath.map((e) => '${e.dx},${e.dy}').join(';');

      // Calculate bounding box
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for(final p in _currentPath) {
        if(p.dx < minX) minX = p.dx;
        if(p.dy < minY) minY = p.dy;
        if(p.dx > maxX) maxX = p.dx;
        if(p.dy > maxY) maxY = p.dy;
      }

      final width = maxX - minX;
      final height = maxY - minY;

      final annotation = model.PdfAnnotation(
        id: _uuid.v4(),
        pageNumber: widget.pageNumber,
        type: widget.currentTool!,
        position: Offset(minX, minY), // Top left bounding box
        size: Size(width > 0 ? width : 1, height > 0 ? height : 1),
        color: widget.currentColor,
        opacity: widget.currentTool == model.PdfAnnotationType.highlight ? 0.3 : 1.0,
        content: pathData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onAnnotationAdded(annotation);
      setState(() {
        _currentPath = [];
      });
    }
  }

  void _showNoteDialog(Offset position, [model.PdfAnnotation? existingAnnotation]) {
     final controller = TextEditingController(text: existingAnnotation?.content ?? '');

     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(existingAnnotation == null ? 'Add Note' : 'Edit Note'),
         content: TextField(
           controller: controller,
           maxLines: 5,
           decoration: const InputDecoration(hintText: 'Enter your note here...'),
         ),
         actions: [
           if (existingAnnotation != null)
             TextButton(
               onPressed: () {
                 widget.onAnnotationRemoved(existingAnnotation.id);
                 Navigator.pop(context);
               },
               child: const Text('Delete', style: TextStyle(color: Colors.red)),
             ),
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
           ),
           TextButton(
             onPressed: () {
                final content = controller.text;
                if(content.isNotEmpty) {
                    if (existingAnnotation != null) {
                      widget.onAnnotationRemoved(existingAnnotation.id);
                    }

                    final newAnnotation = model.PdfAnnotation(
                      id: existingAnnotation?.id ?? _uuid.v4(),
                      pageNumber: widget.pageNumber,
                      type: model.PdfAnnotationType.note,
                      position: position,
                      size: const Size(32, 32),
                      color: Colors.amber,
                      opacity: 1.0,
                      content: content,
                      createdAt: existingAnnotation?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    widget.onAnnotationAdded(newAnnotation);
                }
                Navigator.pop(context);
             },
             child: const Text('Save'),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    final pageAnnotations = widget.document.annotations.where((a) => a.pageNumber == widget.pageNumber).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: widget.currentTool != null ? _handlePanStart : null,
      onPanUpdate: widget.currentTool != null ? _handlePanUpdate : null,
      onPanEnd: widget.currentTool != null ? _handlePanEnd : null,
      child: Stack(
        children: [
          CustomPaint(
            painter: _AnnotationPainter(
              annotations: pageAnnotations,
              currentPath: _currentPath,
              currentTool: widget.currentTool,
              currentColor: widget.currentColor,
            ),
            size: Size.infinite,
          ),
          // Draw note markers over the canvas
          ...pageAnnotations.where((a) => a.type == model.PdfAnnotationType.note).map((note) {
             return Positioned(
               left: note.position.dx,
               top: note.position.dy,
               child: GestureDetector(
                 onTap: () => _showNoteDialog(note.position, note),
                 child: Container(
                   width: 32,
                   height: 32,
                   decoration: BoxDecoration(
                     color: note.color,
                     shape: BoxShape.circle,
                     boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                   ),
                   child: const Icon(Icons.note, size: 20, color: Colors.white),
                 ),
               ),
             );
          }),
        ],
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<model.PdfAnnotation> annotations;
  final List<Offset> currentPath;
  final model.PdfAnnotationType? currentTool;
  final Color currentColor;

  _AnnotationPainter({
    required this.annotations,
    required this.currentPath,
    required this.currentTool,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved annotations
    for (final annotation in annotations) {
      if (annotation.type == model.PdfAnnotationType.pen || annotation.type == model.PdfAnnotationType.highlight) {
        if (annotation.content == null || annotation.content!.isEmpty) continue;

        final paint = Paint()
          ..color = annotation.color.withOpacity(annotation.opacity)
          ..strokeWidth = annotation.type == model.PdfAnnotationType.highlight ? 16.0 : 4.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        // Note: the current pdfrx overlays might scale. The simplified coordinate parsing handles raw paths.
        // For a full implementation, you map widget coordinates back to PDF logical coordinates.
        // We'll draw directly to the canvas scale given by the overlay builder.

        final pointsStr = annotation.content!.split(';');
        if(pointsStr.length < 2) continue;

        final path = Path();
        var first = pointsStr.first.split(',');
        path.moveTo(double.parse(first[0]), double.parse(first[1]));

        for(int i=1; i<pointsStr.length; i++) {
           var pt = pointsStr[i].split(',');
           path.lineTo(double.parse(pt[0]), double.parse(pt[1]));
        }
        canvas.drawPath(path, paint);
      }
    }

    // Draw current path
    if (currentPath.isNotEmpty && (currentTool == model.PdfAnnotationType.pen || currentTool == model.PdfAnnotationType.highlight)) {
      final paint = Paint()
          ..color = currentColor.withOpacity(currentTool == model.PdfAnnotationType.highlight ? 0.3 : 1.0)
          ..strokeWidth = currentTool == model.PdfAnnotationType.highlight ? 16.0 : 4.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPath.first.dx, currentPath.first.dy);
      for (int i = 1; i < currentPath.length; i++) {
        path.lineTo(currentPath[i].dx, currentPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return true; // Simplified repaint logic
  }
}
