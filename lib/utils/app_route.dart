import 'package:flutter/material.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/screens/splash_screen/splash_screen.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case LipReadingScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LipReadingScreen());

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
