import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../ai/widgets/ai_button.dart';

class WriterToolbar extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onAiPressed;

  const WriterToolbar({
    super.key,
    required this.controller,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            return Row(
              children: [
                AIButton(onPressed: onAiPressed),
                Container(width: 1, height: 24, color: Colors.grey),
                Expanded(
                  child: QuillSimpleToolbar(
                    controller: controller,
                    config: QuillSimpleToolbarConfig(
                      multiRowsDisplay: !isTablet,
                      showFontFamily: false,
                      showFontSize: true,
                      showBoldButton: true,
                      showItalicButton: true,
                      showSmallButton: false,
                      showUnderLineButton: true,
                      showStrikeThrough: true,
                      showInlineCode: false,
                      showColorButton: true,
                      showBackgroundColorButton: true,
                      showClearFormat: true,
                      showAlignmentButtons: true,
                      showLeftAlignment: true,
                      showCenterAlignment: true,
                      showRightAlignment: true,
                      showJustifyAlignment: true,
                      showHeaderStyle: true,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: false,
                      showCodeBlock: false,
                      showQuote: true,
                      showIndent: true,
                      showLink: true,
                      showUndo: true,
                      showRedo: true,
                      showDirection: false,
                      showSearchButton: true,
                      showSubscript: true,
                      showSuperscript: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
