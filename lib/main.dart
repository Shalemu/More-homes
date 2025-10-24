import 'package:flutter/material.dart';
import 'package:morehousesapp/screen/login_screen.dart';
import 'package:morehousesapp/screen/register_screen.dart';
import 'package:morehousesapp/screen/home_screen.dart';
import 'package:morehousesapp/screen/splash_screen.dart';
import 'package:morehousesapp/config/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'More Homes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.splash, // or AppRoutes.login
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.registration: (context) => const RegisterScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
      },
    );
  }
}
