import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/core/app_dialog.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:provider/provider.dart';

class InvoiceScreen extends StatefulWidget {
  final String? invoiceUuid;
  const InvoiceScreen({super.key, this.invoiceUuid});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  List invoices = [];
  bool loading = true;
  late AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
    
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted) setState(() {});
  });
  }

  Future<void> fetchInvoices() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      final response = await http.get(
        Uri.parse(ApiConstants.myInvoices),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          invoices = data["data"] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _initiatePayment(String invoiceId, String phone) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      final url = ApiConstants.makePayment(invoiceId);

      AppDialog.loading(context, message: "Sending STK push...");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"phone_number": phone}),
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        AppDialog.success(
          // ignore: use_build_context_synchronously
          context,
          message:
              data["detail"] ??
              "STK push sent. Check your phone to complete payment.",
        );

        fetchInvoices();
 
      } else {
        // ignore: use_build_context_synchronously
        AppDialog.error(context, message: data["detail"] ?? "Payment failed");
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (Navigator.canPop(context)) Navigator.pop(context);
      // ignore: use_build_context_synchronously
      AppDialog.error(context, message: "Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String formatDateTime(String? date) {
    if (date == null || date.isEmpty) return "N/A";

    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      // Example: 01 May 2026, 02:30 PM
    } catch (e) {
      return date;
    }
  }

  String getSmartCountdown(String? date) {
    if (date == null || date.isEmpty) return "00:00:00";

    try {
      final due = DateTime.parse(date);
      final now = DateTime.now();

      final diff = due.difference(now);

      if (diff.isNegative) return "Expired";

      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      String time =
          "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";

      if (days > 0) {
        return "$days ${days == 1 ? 'Day' : 'Days'} $time";
      } else {
        return time;
      }
    } catch (e) {
      return "00:00:00";
    }
  }

  Color getExpiryColor(String? date) {
    if (date == null || date.isEmpty) return Colors.grey;

    try {
      final due = DateTime.parse(date);
      final now = DateTime.now();

      final diff = due.difference(now);

      if (diff.isNegative) return Colors.red;

      if (diff.inHours < 1) return Colors.red;
      if (diff.inHours < 24) return Colors.orange;

      return Colors.green;
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E8F7A),
        title: const Text(
          "My Invoices",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
          ? const Center(
              child: Text(
                "No invoices found",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final inv = invoices[index];

                final status = (inv["status"] ?? "").toString().toLowerCase();

                Color statusColor;
                Color bgColor;
                String statusText;

                switch (status) {
                  case "paid":
                    statusColor = Colors.green;
                    bgColor = Colors.green.withOpacity(0.1);
                    statusText = "PAID";
                    break;

                  case "pending":
                    statusColor = Colors.orange;
                    bgColor = Colors.orange.withOpacity(0.1);
                    statusText = "PENDING";
                    break;

                  case "cancelled":
                    statusColor = Colors.red;
                    bgColor = Colors.red.withOpacity(0.1);
                    statusText = "CANCELLED";
                    break;

                  default:
                    statusColor = Colors.grey;
                    bgColor = Colors.grey.withOpacity(0.1);
                    statusText = status.toUpperCase();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E8F7A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF1E8F7A),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Invoice #${inv["reference"]?.toString().isEmpty == true ? inv["uuid"] : inv["reference"]}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Due: ${formatDateTime(inv["due_date"])}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 6),

                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      getSmartCountdown(inv["due_date"]),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: getExpiryColor(inv["due_date"]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// AMOUNT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Amount"),
                          Text("TZS ${inv["amount"] ?? "0"}"),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// DISCOUNT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Discount"),
                          Text(
                            "TZS ${inv["discount"] ?? "0"}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// TO PAY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Amount to Pay"),
                          Text(
                            "TZS ${inv["amount_to_pay"] ?? "0"}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// ACTIONS
                      if (status == "pending")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E8F7A),
                            ),
                            onPressed: () {
                              AppDialog.payment(
                                context,
                                invoiceId: inv["uuid"].toString(),
                                onPay: (phone) {
                                  _initiatePayment(
                                    inv["uuid"].toString(),
                                    phone,
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.payment,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Pay Now",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      else if (status == "paid")
                        _statusBox("Payment Completed", Colors.green)
                      else if (status == "cancelled")
                        _statusBox("Invoice Cancelled", Colors.red),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusBox(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
