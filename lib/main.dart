import 'package:flutter/material.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
    // Wrap MaterialApp with Consumer to rebuild on language change
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.loadUserFromPrefs();

        return MaterialApp(
          title: 'More Homes',
          debugShowCheckedModeBanner: false,
          locale: langProvider.locale, // 🔹 dynamic locale
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.registration: (context) => const RegisterScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
          },
          onGenerateRoute: (settings) {
            // Property Detail Screen with arguments
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
