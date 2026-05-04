import 'package:flutter/material.dart';
import 'package:morehomesapp/view/update_screen.dart';

class ApiHandler {
  static void handle(
    BuildContext context,
    Map<String, dynamic> json,
  ) {
    final msg = json['msg'];
    final forceUpdate = json['force_update'] ?? false;

    /// 🚨 FORCE UPDATE CHECK
    if (forceUpdate == true ||
        (msg != null && msg.toString().toLowerCase().contains("update"))) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(message: msg),
        ),
        (route) => false,
      );
    }
  }
}