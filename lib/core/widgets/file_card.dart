import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum FileType {
  writer,
  spreadsheet,
  presentation,
  pdf,
  folder,
  unknown,
}

class FileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final FileType type;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const FileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIcon(context),
                  if (onMoreTap != null)
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: onMoreTap,
                      iconSize: 20,
                      color: Theme.of(context).colorScheme.outline,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }
}
