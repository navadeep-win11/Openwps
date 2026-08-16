import 'package:flutter/material.dart';
import 'bottom_navigation.dart';
import 'navigation_rail.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavigationTap;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavigationTap,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Tablet layout
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                CustomNavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onNavigationTap,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        } else {
          // Phone layout
          return Scaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: currentIndex,
              onTap: onNavigationTap,
            ),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }
}
