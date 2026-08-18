import 'package:flutter/material.dart';
import '../../../storage/models/presentation_document.dart';

class SlideSorter extends StatelessWidget {
  final PresentationDocument document;
  final Function(String) onSlideSelected;
  final VoidCallback onAddSlide;
  final Function(String) onSlideOptions;

  const SlideSorter({
    super.key,
    required this.document,
    required this.onSlideSelected,
    required this.onAddSlide,
    required this.onSlideOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: onAddSlide,
            tooltip: 'Add Slide',
            iconSize: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Container(width: 1, height: 60, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: document.slides.length,
              itemBuilder: (context, index) {
                final slide = document.slides[index];
                final isActive = slide.id == document.activeSlide;

                return GestureDetector(
                  onTap: () => onSlideSelected(slide.id),
                  onLongPress: () => onSlideOptions(slide.id),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(slide.background.replaceAll('#', '0xFF'))),
                      border: Border.all(
                        color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                        width: isActive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            slide.name,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
