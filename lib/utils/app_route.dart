import 'package:flutter/material.dart';
import 'package:lip_reading/screens/layout/app_shell.dart';
import 'package:lip_reading/screens/auth/signup_screen.dart';
import 'package:lip_reading/screens/splash_screen/history_screen.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';
import 'package:lip_reading/screens/splash_screen/splash_screen.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppShell.routeName:
        return MaterialPageRoute(builder: (_) => const AppShell());
      case LipReadingScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LipReadingScreen());
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case SignupScreen.routeName:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case HistoryScreen.routeName:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());

      default:
        return MaterialPageRoute(builder: (_) => errorRoute());
    }
  }

  static Widget errorRoute() {
    return const Scaffold(
      body: Center(
        child: Text('Error: Route not found'),
      ),
    );
  }
}
