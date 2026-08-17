import 'package:flutter/material.dart';

class SpreadsheetToolbar extends StatelessWidget {
  final Map<String, dynamic> currentStyle;
  final Function(String key, dynamic value) onStyleChanged;
  final VoidCallback onAddRow;
  final VoidCallback onDeleteRow;
  final VoidCallback onAddColumn;
  final VoidCallback onDeleteColumn;

  const SpreadsheetToolbar({
    super.key,
    required this.currentStyle,
    required this.onStyleChanged,
    required this.onAddRow,
    required this.onDeleteRow,
    required this.onAddColumn,
    required this.onDeleteColumn,
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
              _buildToggleButton(
                icon: Icons.format_underlined,
                isActive: currentStyle['underline'] == true,
                onPressed: () => onStyleChanged('underline', !(currentStyle['underline'] == true)),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              _buildColorButton(
                context,
                icon: Icons.format_color_text,
                colorValue: currentStyle['color'],
                onColorSelected: (color) => onStyleChanged('color', color),
              ),
              _buildColorButton(
                context,
                icon: Icons.format_color_fill,
                colorValue: currentStyle['background'],
                onColorSelected: (color) => onStyleChanged('background', color),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              _buildToggleButton(
                icon: Icons.format_align_left,
                isActive: currentStyle['align'] == 'left',
                onPressed: () => onStyleChanged('align', 'left'),
              ),
              _buildToggleButton(
                icon: Icons.format_align_center,
                isActive: currentStyle['align'] == 'center',
                onPressed: () => onStyleChanged('align', 'center'),
              ),
              _buildToggleButton(
                icon: Icons.format_align_right,
                isActive: currentStyle['align'] == 'right',
                onPressed: () => onStyleChanged('align', 'right'),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.table_rows),
                onPressed: onAddRow,
                tooltip: 'Add Row',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDeleteRow,
                tooltip: 'Delete Selected Row',
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.view_column),
                onPressed: onAddColumn,
                tooltip: 'Add Column',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: onDeleteColumn,
                tooltip: 'Delete Selected Column',
              ),
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
