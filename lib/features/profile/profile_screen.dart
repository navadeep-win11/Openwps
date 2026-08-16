import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'User Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('user@example.com'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
