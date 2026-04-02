import 'package:flutter/material.dart';
import 'package:morehomesapp/view/invoice_screen%20.dart';
import 'package:morehomesapp/view/plans_screen.dart';

void handleNavigation(BuildContext context, String path) {
  final normalizedPath = path.toLowerCase().trim();

  debugPrint("NAVIGATION CALLED");
  debugPrint("RAW PATH: $path");
  debugPrint("NORMALIZED PATH: $normalizedPath");

  switch (normalizedPath) {
    case "plans":
      debugPrint("GOING TO PLANS SCREEN");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      );
      break;

    case "invoice":
      debugPrint("GOING TO INVOICE SCREEN");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InvoiceScreen()),
      );
      break;

    default:
      debugPrint("UNKNOWN PATH: $normalizedPath");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unknown route: $normalizedPath"),
        ),
      );
  }
}