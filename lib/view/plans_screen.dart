import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/core/app_dialog.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/utils/navigation_helper.dart';
import 'package:provider/provider.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<dynamic> plans = [];
  int selectedIndex = 0;
  final formatter = NumberFormat("#,##0", "en_US");

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.plans),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          plans = data["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to load plans";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

Future<void> subscribeToPlan(String planUuid) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null || token.isEmpty) {
      AppDialog.loginRequired(
        context,
        onLogin: () {
          Navigator.pop(context);
        },
      );
      return;
    }

    final response = await http.post(
      Uri.parse(ApiConstants.subscribe(planUuid)),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = json.decode(response.body);

    final String path =
        (data["path"] ?? "plans").toString().toLowerCase();

    final String message =
        (data["detail"] ?? "").toString().toLowerCase();

    debugPrint("SUBSCRIBE RESPONSE: $data");

    /// =========================
    /// SUCCESS FLOW
    /// =========================
    if (response.statusCode == 200 || data["status_code"] == 200) {
      handleNavigation(context, path);
      return;
    }

    /// =========================
    /// ALREADY SUBSCRIBED FLOW
    /// =========================
    if (message.contains("active subscription")) {
      AppDialog.redirectToInvoice(
        context,
        onViewInvoice: () {
          handleNavigation(context, "invoice");
        },
      );
      return;
    }

    /// =========================
    /// ERROR FLOW
    /// =========================
    AppDialog.error(context, message: message.isEmpty ? "Failed" : message);
  } catch (e) {
    AppDialog.error(context, message: "Network error: $e");
  }
}
  

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(error!, style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }

    final plan = plans[selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.primary, Color(0xFF0B0B12)],
                radius: 1.2,
              ),
            ),
          ),

          /// CONTENT
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pricing",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Choose your subscription plan",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 20),

                      /// PLAN SELECTOR (dynamic)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(plans.length, (index) {
                              final isActive = selectedIndex == index;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: 250.ms,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    plans[index]["billing_cycle_name"]
                                            ?.toString()
                                            .toUpperCase() ??
                                        "",
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// PRICE
                      Text(
                        "${formatter.format(double.parse(plan["actual_price"].toString()))} TZS",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fade().scale(),

                      const SizedBox(height: 4),

                      Text(
                        "${plan["name"]}",
                        style: const TextStyle(color: Colors.white60),
                      ),

                      const SizedBox(height: 10),

                      /// DISCOUNT BADGE
                      if ((plan["discount_per"] ?? "0") != "0")
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "-${plan["discount_per"]}% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      /// FEATURES (static for now)
                      _feature("Full access to properties"),
                      _feature("Priority support"),
                      _feature("Unlimited browsing"),
                      _feature("Contact owners directly"),

                      const SizedBox(height: 20),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final plan = plans[selectedIndex];
                            subscribeToPlan(plan["uuid"]);
                          },
                          child: const Text(
                            "Subscribe Now",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Terms • Privacy • Restore",
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
