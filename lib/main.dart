import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/routes.dart';
import 'config/supabase_config.dart';
import 'screens/landing/mainlanding.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/management_login_page.dart'; // NEW
import 'screens/establishment/establishment_dashboard.dart';
import 'screens/admin/administrator_dashboard.dart';
import 'screens/admin/super_admin_dashboard.dart';
import 'widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );

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
      initialRoute: AppRoutes.landing,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case AppRoutes.landing:
            page = const MainLandingPage();
            break;
          case AppRoutes.login:
            page = const LoginPage();
            break;
          case AppRoutes.register:
            page = const RegisterPage();
            break;
          case AppRoutes.managementLogin: // NEW
            page = const ManagementLoginPage();
            break;
          case AppRoutes.home:
            page = const MainNavigation(initialIndex: 0);
            break;
          case AppRoutes.plan:
            page = const MainNavigation(initialIndex: 1);
            break;
          case AppRoutes.map:
            page = const MainNavigation(initialIndex: 2);
            break;
          case AppRoutes.favorite:
            page = const MainNavigation(initialIndex: 3);
            break;
          case AppRoutes.profile:
            page = const MainNavigation(initialIndex: 4);
            break;
          case AppRoutes.establishment:
            page = const EstablishmentDashboard();
            break;
          case AppRoutes.administrator:
            page = const AdministratorDashboard();
            break;
          case AppRoutes.superAdmin:
            page = const SuperAdminDashboard();
            break;
          default:
            page = const MainLandingPage();
        }

        final isTabRoute = AppRoutes.touristRoutes.contains(settings.name);
        final args = settings.arguments as Map<String, dynamic>?;
        final isTabSwitch = args?['isTabSwitch'] == true;

        if (settings.name == AppRoutes.login ||
            settings.name == AppRoutes.register ||
            settings.name == AppRoutes.managementLogin || // NEW
            isTabRoute) {
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