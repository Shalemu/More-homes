import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/theme/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backend_apis.dart';
import '../view/order_details.dart';

enum DialogType { payment, success, error, info }

class PaymentHistoryScreen extends StatefulWidget {
  final String? orderId;
  final String? userId;

  const PaymentHistoryScreen({super.key, this.orderId, this.userId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> payments = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  /// Fetch payment history
  Future<void> fetchPaymentHistory() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');

      if (token == null || token.isEmpty) {
        setState(() {
          message = "Access token not found. Please login again.";
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse("${ApiConstants.paymentHistory}/"); 
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200) {
        payments = data?["data"] ?? [];
        setState(() {
          isLoading = false;
          message = payments.isEmpty ? "No payments found." : '';
        });
      } else if (response.statusCode == 404) {
        payments = [];
        setState(() {
          message = data != null
              ? (data['detail'] ?? "No payments found for your account.")
              : "No payments found for your account.";
          isLoading = false;
        });
      } else {
        payments = [];
        setState(() {
          message =
              'Failed to load payment history. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      payments = [];
      setState(() {
        message = 'Error loading payment history: $e';
        isLoading = false;
      });
    }
  }

  /// Show Airbnb-style animated dialog
  Future<void> showCustomDialog(String message,
      {DialogType type = DialogType.error}) async {
    Color iconColor;
    String title;

    switch (type) {
      case DialogType.success:
        iconColor = AppColors.primary;
        title = "Success";
        break;
      case DialogType.error:
        iconColor = AppColors.danger;
        title = "Error";
        break;
      case DialogType.info:
        iconColor = AppColors.secondary;
        title = "Info";
        break;
      case DialogType.payment:
        iconColor = AppColors.accent;
        title = "Payment Required";
        break;
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == DialogType.success
                          ? Icons.check_circle
                          : type == DialogType.error
                              ? Icons.error
                              : type == DialogType.info
                                  ? Icons.info
                                  : Icons.payment,
                      size: 64,
                      color: iconColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// View the most recent order
  Future<void> viewOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null || token.isEmpty) {
      await showCustomDialog("Please login again.", type: DialogType.error);
      return;
    }

    final url = Uri.parse("${ApiConstants.paymentUrl}/");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      dynamic jsonBody;
      try {
        jsonBody = json.decode(response.body);
      } catch (_) {
        jsonBody = null;
      }

      if (response.statusCode == 200) {
        if (jsonBody == null || jsonBody["data"] == null || jsonBody["data"].isEmpty) {
          await showCustomDialog("No active order found.", type: DialogType.info);
          return;
        }

        final order = jsonBody["data"][0];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      } else if (response.statusCode == 404) {
        await showCustomDialog(
          jsonBody != null
              ? (jsonBody['detail'] ?? "No order found.")
              : "No order found.",
          type: DialogType.info,
        );
      } else {
        await showCustomDialog(
          "Failed to load order: ${response.statusCode}",
          type: DialogType.error,
        );
      }
    } catch (e) {
      await showCustomDialog("Error fetching order: $e", type: DialogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Payment History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(message),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: viewOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          "View Order",
                          style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final pay = payments[index];
                    return ListTile(
                      title: Text("Amount: ${pay["amount"]}"),
                      subtitle: Text("Date: ${pay["created_at"]}"),
                      trailing: Text(pay["status"]),
                      onTap: viewOrder,
                    );
                  },
                ),
    );
  }
}