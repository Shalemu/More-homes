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

  final authProvider = AuthProvider();

  // Load session only (no routing logic here)
  await authProvider.loadUserFromPrefs();

  // UI setup
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'More Homes',
      debugShowCheckedModeBanner: false,

      // Localization
      locale: lang.locale,
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

      
      home: const SplashScreen(),

      // Routes
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.registration: (context) => const RegisterScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
      },

      // Dynamic route
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
  }
}