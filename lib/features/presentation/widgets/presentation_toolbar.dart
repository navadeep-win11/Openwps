import 'package:flutter/material.dart';
import '../../ai/widgets/ai_button.dart';

class PresentationToolbar extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback onDeleteElement;
  final bool hasSelection;
  final Map<String, dynamic> currentStyle;
  final Function(String key, dynamic value) onStyleChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onAiPressed;

  const PresentationToolbar({
    super.key,
    required this.onAddText,
    required this.onAddImage,
    required this.onBringForward,
    required this.onSendBackward,
    required this.onDeleteElement,
    required this.hasSelection,
    required this.currentStyle,
    required this.onStyleChanged,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onAiPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              AIButton(onPressed: onAiPressed),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: canUndo ? onUndo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: canRedo ? onRedo : null,
                tooltip: 'Redo',
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.title),
                onPressed: onAddText,
                tooltip: 'Add Text',
              ),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: onAddImage,
                tooltip: 'Add Image',
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              if (hasSelection) ...[
                _buildToggleButton(
                  icon: Icons.format_bold,
                  isActive: currentStyle['bold'] == true,
                  onPressed: () => onStyleChanged('bold', !(currentStyle['bold'] == true)),
                ),
                _buildToggleButton(
                  icon: Icons.format_italic,
                  isActive: currentStyle['italic'] == true,
                  onPressed: () => onStyleChanged('italic', !(currentStyle['italic'] == true)),
                ),
                 _buildColorButton(
                  context,
                  icon: Icons.format_color_text,
                  colorValue: currentStyle['color'],
                  onColorSelected: (color) => onStyleChanged('color', color),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.grey[400]),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.flip_to_front),
                  onPressed: onBringForward,
                  tooltip: 'Bring Forward',
                ),
                IconButton(
                  icon: const Icon(Icons.flip_to_back),
                  onPressed: onSendBackward,
                  tooltip: 'Send Backward',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: onDeleteElement,
                  tooltip: 'Delete',
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Select an element to edit'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({required IconData icon, required bool isActive, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? Colors.blue : null,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      splashRadius: 20,
    );
  }

   Widget _buildColorButton(BuildContext context, {required IconData icon, required String? colorValue, required Function(String?) onColorSelected}) {
    Color? displayColor;
    if (colorValue != null) {
       try {
         displayColor = Color(int.parse(colorValue.replaceAll('#', '0xFF')));
       } catch (_) {}
    }

    return IconButton(
      icon: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Icon(icon),
          Container(
            height: 4,
            width: 16,
            margin: const EdgeInsets.only(bottom: 2),
            color: displayColor ?? Colors.black,
          )
        ],
      ),
      onPressed: () {
        // Mock color selection - cycle through basics for this milestone
        if (colorValue == null || colorValue == '#000000') {
           onColorSelected('#FF0000'); // red
        } else if (colorValue == '#FF0000') {
           onColorSelected('#0000FF'); // blue
        } else {
           onColorSelected(null); // clear
        }
      },
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      splashRadius: 20,
    );
  }
}
