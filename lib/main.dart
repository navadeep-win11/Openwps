import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'core/routing/router.dart';

void main() {
  runApp(const OpenWPSApp());
}

class OpenWPSApp extends StatelessWidget {
  const OpenWPSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenWPS',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
