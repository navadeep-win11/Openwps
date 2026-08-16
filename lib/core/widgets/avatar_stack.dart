import 'package:flutter/material.dart';

class AvatarStack extends StatelessWidget {
  final List<String> imageUrls;
  final double size;

  const AvatarStack({
    super.key,
    required this.imageUrls,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrls = imageUrls.take(3).toList();
    final remainingCount = imageUrls.length - displayUrls.length;

    return SizedBox(
      width: size + (size * 0.6 * (displayUrls.length - 1)) + (remainingCount > 0 ? size * 0.6 : 0),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < displayUrls.length; i++)
            Positioned(
              left: i * (size * 0.6),
              child: _buildAvatar(context, displayUrls[i], i),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayUrls.length * (size * 0.6),
              child: _buildMoreIndicator(context, remainingCount),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String url, int index) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundImage: NetworkImage(url),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int count) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
