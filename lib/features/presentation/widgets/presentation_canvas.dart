import 'package:flutter/material.dart';
import '../../../storage/models/presentation_document.dart';
import 'presentation_element_widget.dart';

class PresentationCanvas extends StatelessWidget {
  final SlideData slide;
  final String? selectedElementId;
  final Function(String) onElementSelected;
  final Function(String, double, double) onElementDragged;
  final VoidCallback onDragEnd;
  final Function(String, double, double) onElementResized;
  final VoidCallback onResizeEnd;
  final Function(String, String) onElementContentChanged;

  static const double logicalWidth = 1920.0;
  static const double logicalHeight = 1080.0;

  const PresentationCanvas({
    super.key,
    required this.slide,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onElementDragged,
    required this.onDragEnd,
    required this.onElementResized,
    required this.onResizeEnd,
    required this.onElementContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scaling factor to fit 16:9 logical canvas into the available view
        final scaleX = constraints.maxWidth / logicalWidth;
        final scaleY = constraints.maxHeight / logicalHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY; // Use min to fit entirely

        final actualWidth = logicalWidth * scale;
        final actualHeight = logicalHeight * scale;

        return Center(
          child: Container(
            width: actualWidth,
            height: actualHeight,
            decoration: BoxDecoration(
              color: Color(int.parse(slide.background.replaceAll('#', '0xFF'))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: logicalWidth,
                height: logicalHeight,
                child: GestureDetector(
                  onTap: () => onElementSelected(''), // Deselect when tapping background
                  child: _buildElements(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElements() {
    final elements = List<SlideElement>.from(slide.elements);
    elements.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / logicalWidth;
        final scaleY = constraints.maxHeight / logicalHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        return Stack(
          clipBehavior: Clip.none,
          children: elements.map<Widget>((element) {
            return PresentationElementWidget(
              element: element,
              isSelected: selectedElementId == element.id,
              onTap: () => onElementSelected(element.id),
              onDragStart: onDragEnd, // Using End to trigger history push at start
              onDragUpdate: (details) {
                 onElementDragged(element.id, details.delta.dx / scale, details.delta.dy / scale);
              },
              onDragEnd: onDragEnd,
              onResizeStart: onResizeEnd,
              onResizeUpdate: (details) {
                onElementResized(element.id, details.delta.dx / scale, details.delta.dy / scale);
              },
              onResizeEnd: onResizeEnd,
              onContentChanged: (content) {
                onElementContentChanged(element.id, content);
              },
            );
          }).toList(),
        );
      }
    );
  }
}
