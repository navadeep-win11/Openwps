import 'package:flutter/material.dart';
import 'file_card.dart';
import '../theme/colors.dart';

class FileListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final FileType type;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const FileListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onMoreTap != null)
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: onMoreTap,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData iconData;
    Color color;

    switch (type) {
      case FileType.writer:
        iconData = Icons.description;
        color = AppColors.writerBlue;
        break;
      case FileType.spreadsheet:
        iconData = Icons.table_chart;
        color = AppColors.sheetEmerald;
        break;
      case FileType.presentation:
        iconData = Icons.slideshow;
        color = AppColors.slideOrange;
        break;
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        color = AppColors.pdfRed;
        break;
      case FileType.folder:
        iconData = Icons.folder;
        color = Theme.of(context).colorScheme.secondary;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Theme.of(context).colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }
}
