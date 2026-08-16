import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Welcome to OpenWPS'),
            subtitle: Text('Get started with creating your first document.'),
          ),
          ListTile(
            leading: Icon(Icons.update),
            title: Text('App Update Available'),
            subtitle: Text('Version 1.0.1 is now available.'),
          ),
        ],
      ),
    );
  }
}
