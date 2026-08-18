import 'package:flutter/material.dart';

class PresentationToolbar extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback onDeleteElement;
  final bool hasSelection;
  final Map<String, dynamic> currentStyle;
  final Function(String, dynamic) onStyleChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
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
              _buildToggleButton(
                icon: Icons.format_bold,
                isActive: currentStyle['bold'] == true,
                onPressed: hasSelection ? () => onStyleChanged('bold', !(currentStyle['bold'] == true)) : null,
              ),
              _buildToggleButton(
                icon: Icons.format_italic,
                isActive: currentStyle['italic'] == true,
                onPressed: hasSelection ? () => onStyleChanged('italic', !(currentStyle['italic'] == true)) : null,
              ),
              _buildToggleButton(
                icon: Icons.format_underlined,
                isActive: currentStyle['underline'] == true,
                onPressed: hasSelection ? () => onStyleChanged('underline', !(currentStyle['underline'] == true)) : null,
              ),
              _buildColorButton(
                context,
                icon: Icons.format_color_text,
                colorValue: currentStyle['color'],
                onColorSelected: hasSelection ? (color) => onStyleChanged('color', color) : null,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              _buildToggleButton(
                icon: Icons.format_align_left,
                isActive: currentStyle['align'] == 'left' || currentStyle['align'] == null,
                onPressed: hasSelection ? () => onStyleChanged('align', 'left') : null,
              ),
              _buildToggleButton(
                icon: Icons.format_align_center,
                isActive: currentStyle['align'] == 'center',
                onPressed: hasSelection ? () => onStyleChanged('align', 'center') : null,
              ),
              _buildToggleButton(
                icon: Icons.format_align_right,
                isActive: currentStyle['align'] == 'right',
                onPressed: hasSelection ? () => onStyleChanged('align', 'right') : null,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.flip_to_front),
                onPressed: hasSelection ? onBringForward : null,
                tooltip: 'Bring Forward',
              ),
              IconButton(
                icon: const Icon(Icons.flip_to_back),
                onPressed: hasSelection ? onSendBackward : null,
                tooltip: 'Send Backward',
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: hasSelection ? onDeleteElement : null,
                tooltip: 'Delete Element',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({required IconData icon, required bool isActive, required VoidCallback? onPressed}) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? Colors.blue : null,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      splashRadius: 20,
    );
  }

  Widget _buildColorButton(BuildContext context, {required IconData icon, required String? colorValue, required Function(String?)? onColorSelected}) {
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
      onPressed: onColorSelected != null ? () {
        if (colorValue == null || colorValue == '#000000') {
           onColorSelected('#FF0000');
        } else if (colorValue == '#FF0000') {
           onColorSelected('#0000FF');
        } else {
           onColorSelected(null);
        }
      } : null,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      splashRadius: 20,
    );
  }
}
