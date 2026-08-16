import 'package:flutter/material.dart';
import '../widgets/responsive_scaffold.dart';
import '../../features/home/home_screen.dart';
import '../../features/files/files_screen.dart';
import '../../features/create/create_screen.dart';
import '../../features/ai/ai_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/templates/templates_screen.dart';
import '../../features/notifications/notifications_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/templates':
        return MaterialPageRoute(builder: (_) => const TemplatesScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FilesScreen(),
    const CreateScreen(),
    const AiScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onNavigationTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _screens[_currentIndex],
    );
  }
}
