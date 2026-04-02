import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:morehomesapp/models/property_model.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/providers/feedback_provider.dart';
import 'package:morehomesapp/providers/language_provider.dart';
import 'package:morehomesapp/providers/property_provider.dart';

import 'package:morehomesapp/view/splash_screen.dart';
import 'package:morehomesapp/view/login_screen.dart';
import 'package:morehomesapp/view/register_screen.dart';
import 'package:morehomesapp/view/home_screen.dart';
import 'package:morehomesapp/view/property_details_screen.dart';

import 'package:morehomesapp/l10n/app_localizations.dart';
import 'package:morehomesapp/config/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize providers before app starts
  final authProvider = AuthProvider();
  await authProvider.loadUserFromPrefs();

  // Enable edge-to-edge UI (fix Play Store warning)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Optional: Transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        return MaterialApp(
          title: 'More Homes',
          debugShowCheckedModeBanner: false,

          // Localization
          locale: langProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),

          // Navigation
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.registration: (context) => const RegisterScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
          },

          // Dynamic routes
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.propertyDetail) {
              final property = settings.arguments as PropertyModel;
              return MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: property),
              );
            }
            return null;
          },
        );
      },
    );
  }
}