import 'package:flutter/material.dart';
import 'package:morehomesapp/view/update_screen.dart';

class UpdateManager {
  static void check(
    BuildContext context, {
    String? msg,
  }) {
    if (msg != null && msg.toLowerCase().contains("update")) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(message: msg),
          ),
          (route) => false,
        );
      });
    }
  }
}