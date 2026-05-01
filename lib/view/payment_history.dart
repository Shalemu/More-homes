import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backend_apis.dart';
import 'invoice_details.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> payments = [];
  bool isLoading = true;
  String message = '';

  late AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    fetchPaymentHistory();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,##0').format(amount);
  }

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
          message = "Session expired. Please login again.";
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse("${ApiConstants.myInvoices}?paid=true");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          payments = data["data"] ?? [];
          isLoading = false;
          message = payments.isEmpty ? "No paid invoices found." : '';
        });

        _controller.forward(from: 0);
      } else {
        setState(() {
          payments = [];
          message = data["detail"] ?? "Failed to load payment history.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        payments = [];
        message = "Error: $e";
        isLoading = false;
      });
    }
  }

  void openInvoice(dynamic invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
    );
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
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Payment History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: fetchPaymentHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final pay = payments[index];

                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      (1 / payments.length) * index,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _buildCard(pay),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildCard(dynamic pay) {
    final status = (pay["status"] ?? "").toString().toLowerCase();

    Color statusColor;
    Color bgColor;
    String statusText;

    switch (status) {
      case "paid":
        statusColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.12);
        statusText = "PAID";
        break;

      case "pending":
        statusColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.12);
        statusText = "PENDING";
        break;

      case "cancelled":
        statusColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.12);
        statusText = "CANCELLED";
        break;

      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.12);
        statusText = status.toUpperCase();
    }

    return GestureDetector(
      onTap: () => openInvoice(pay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      "Invoice Payment",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              "TZS ${formatMoney(pay["amount_to_pay"])}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.tag, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "Ref: ${pay["reference"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATE
                Text(
                  "Due: ${formatDateTime(pay["due_date"])}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.timer, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      getSmartCountdown(pay["due_date"]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: getExpiryColor(pay["due_date"]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Payments Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message.isEmpty ? "You haven't made any payments yet." : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchPaymentHistory,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
