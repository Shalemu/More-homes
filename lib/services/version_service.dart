import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/view/update_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static final String apiUrl = ApiConstants.appVersionConfig;
  static bool _hasChecked = false;

  /// Checks the server once per app run. Returns true when the update screen
  /// was opened, so the splash screen can avoid navigating over it.
  static Future<bool> check(BuildContext context) async {
    if (_hasChecked) return false;
    _hasChecked = true;

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode != 200 || !context.mounted) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      final data = decoded;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version.split('+').first;
      final minimumVersion = data['minimum_version']?.toString();
      final latestVersion = data['latest_version']?.toString();
      final forceUpdate = data['force_update'] == true;
      final message = data['message']?.toString();

      String? updateUrl;
      if (Platform.isAndroid) {
        updateUrl = data['android_apk_url']?.toString();
      } else if (Platform.isIOS) {
        updateUrl = data['apple_apk_url']?.toString();
      }

      final updateRequired =
          (minimumVersion != null &&
              _isLower(currentVersion, minimumVersion)) ||
          (latestVersion != null &&
              _isLower(currentVersion, latestVersion) &&
              forceUpdate);

      if (!updateRequired || !context.mounted) return false;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ForceUpdateScreen(
            message: message,
            updateUrl: updateUrl,
          ),
        ),
        (route) => false,
      );
      return true;
    } catch (e) {
      debugPrint('Version check failed: $e');
      return false;
    }
  }

  static bool _isLower(String current, String target) {
    final currentParts = current.split('.').map(int.parse).toList();
    final targetParts = target.split('.').map(int.parse).toList();

    for (var i = 0; i < targetParts.length; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final targetPart = targetParts[i];
      if (currentPart < targetPart) return true;
      if (currentPart > targetPart) return false;
    }
    return false;
  }
}
