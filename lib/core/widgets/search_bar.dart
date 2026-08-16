import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search',
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.outline,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
