import 'package:flutter/material.dart';
import 'widgets/ai_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: false,
            onChanged: (val) {},
          ),
          ListTile(
            title: const Text('Default Storage'),
            subtitle: const Text('Local Device'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('AI Preferences'),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const AISettingsScreen()),
               );
            },
          ),
          ListTile(
            title: const Text('About OpenWPS'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
