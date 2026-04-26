import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const String _firstInstallKey = "first_install";


  static Future<bool> isFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstInstallKey) ?? true;
  }

 
  static Future<void> setNotFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstInstallKey, false);
  }

 
  static Future<void> resetFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstInstallKey);
  }
}