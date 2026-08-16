import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'More'),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_queue),
            title: const Text('Storage & Sync'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Feedback'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
