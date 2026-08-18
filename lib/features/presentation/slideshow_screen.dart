import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../storage/models/presentation_document.dart';
import 'widgets/presentation_element_widget.dart';

class SlideshowScreen extends StatefulWidget {
  final PresentationDocument document;

  const SlideshowScreen({super.key, required this.document});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start at active slide
    _currentIndex = widget.document.slides.indexWhere((s) => s.id == widget.document.activeSlide);
    if (_currentIndex == -1) _currentIndex = 0;

    // Hide system UI for immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextSlide() {
    if (_currentIndex < widget.document.slides.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // End of presentation
      Navigator.pop(context);
    }
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.slides.isEmpty) {
      return const Scaffold(body: Center(child: Text('No slides available')));
    }

    final slide = widget.document.slides[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _nextSlide,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _nextSlide();
          } else if (details.primaryVelocity! > 0) {
            _previousSlide();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            const logicalWidth = 1920.0;
            const logicalHeight = 1080.0;

            final scaleX = constraints.maxWidth / logicalWidth;
            final scaleY = constraints.maxHeight / logicalHeight;
            final scale = scaleX < scaleY ? scaleX : scaleY;

            final actualWidth = logicalWidth * scale;
            final actualHeight = logicalHeight * scale;

            return Center(
              child: Container(
                width: actualWidth,
                height: actualHeight,
                decoration: BoxDecoration(
                  color: Color(int.parse(slide.background.replaceAll('#', '0xFF'))),
                ),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: logicalWidth,
                    height: logicalHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _buildElements(slide),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildElements(SlideData slide) {
    final elements = List<SlideElement>.from(slide.elements);
    elements.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return elements.map<Widget>((element) {
      return PresentationElementWidget(
        element: element,
        isSelected: false, // No selection in slideshow
        onTap: () {}, // No-op
        onDragUpdate: (_) {}, // No-op
        onResizeUpdate: (_) {}, // No-op
        onContentChanged: (_) {}, // No-op
      );
    }).toList();
  }
}
