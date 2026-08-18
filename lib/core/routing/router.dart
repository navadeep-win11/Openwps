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
import '../../features/writer/writer_screen.dart';
import '../../features/spreadsheet/spreadsheet_screen.dart';
import '../../features/presentation/presentation_screen.dart';

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
      case '/writer':
        final documentId = settings.arguments as String?;
        if (documentId == null) {
          return _errorRoute('Document ID is required');
        }
        return MaterialPageRoute(builder: (_) => WriterScreen(documentId: documentId));
      case '/spreadsheet':
        final documentId = settings.arguments as String?;
        if (documentId == null) {
          return _errorRoute('Document ID is required');
        }
        return MaterialPageRoute(builder: (_) => SpreadsheetScreen(documentId: documentId));
      case '/presentation':
        final documentId = settings.arguments as String?;
        if (documentId == null) {
          return _errorRoute('Document ID is required');
        }
        return MaterialPageRoute(builder: (_) => PresentationScreen(documentId: documentId));
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
     return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(message)),
          ),
        );
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
