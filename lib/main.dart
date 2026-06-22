import 'package:flutter/material.dart';
import 'screens/landing/mainlanding.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'widgets/main_navigation.dart';

void main() {
  runApp(const SamalNavApp());
}

class SamalNavApp extends StatelessWidget {
  const SamalNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samal Nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),

      // ─── Custom Page Routes (Slide Up Animation) ────────────────────
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const MainLandingPage();
            break;
          case '/login':
            page = const LoginPage();
            break;
          case '/register':
            page = const RegisterPage();
            break;
          case '/home': page = const MainNavigation(initialIndex: 0); break;
          case '/world': page = const MainNavigation(initialIndex: 1); break;
          case '/message': page = const MainNavigation(initialIndex: 2); break;
          case '/favorite': page = const MainNavigation(initialIndex: 3); break;
          case '/profile': page = const MainNavigation(initialIndex: 4); break;
          default: page = const MainLandingPage();
        }

        final isTabRoute = ['/home', '/world', '/message', '/favorite', '/profile'].contains(settings.name);
        final args = settings.arguments as Map<String, dynamic>?;
        final isTabSwitch = args?['isTabSwitch'] == true;

        if (settings.name == '/login' || settings.name == '/register' || isTabRoute) {
          return PageRouteBuilder(
            settings: settings,
            opaque: false, 
            transitionDuration: isTabSwitch ? Duration.zero : const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (isTabSwitch) return child; 
              
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          );
        }

        return MaterialPageRoute(builder: (context) => page, settings: settings);
      },
    );
  }
}
