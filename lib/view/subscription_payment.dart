import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:morehomesapp/view/order_details.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_providers.dart';
import '../theme/app_color.dart';
import 'payment_web_view.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? order;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You must login to view subscriptions."),
          ),
        );
        Navigator.pop(context);
      });
    } else {
      fetchSubscriptionOrder(authProvider.accessToken!);
    }
  }

  Future<void> fetchSubscriptionOrder(String token) async {
    setState(() => isLoading = true);
    final url = Uri.parse("http://213.199.45.65:9099/payment/my-order");
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          order = data['data'][0]; // take the first order
        } else {
          order = null;
        }
      } else {
        order = null;
      }
    } catch (e) {
      order = null;
      debugPrint("Error fetching subscription order: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Premium Subscription",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? _noSubscriptionUI()
          : _subscriptionDetailUI(),
    );
  }

  /// UI for no active subscription
  Widget _noSubscriptionUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "No Active Subscription",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Subscribe now to unlock premium features like advanced search, "
            "exclusive property listings, and more!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// UI for active subscription
  Widget _subscriptionDetailUI() {
    final bool isPaid = order!['is_paid'];
    final String orderId = order!['order_id'];
    final String amount = order!['amount'];
    final String nextPayment = order!['next_payment_date'];
    final String paymentUrl = order!['payment_gateway_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Premium Badge & Card
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade200.withOpacity(0.3),
                      Colors.orange.shade100.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade100.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Premium Subscription",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "PREMIUM",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Order ID
                    _detailRow("Order ID", orderId),
                    const SizedBox(height: 10),

                    // Amount
                    _detailRow("Amount", amount, valueColor: Colors.green),
                    const SizedBox(height: 10),

                    // Next Payment Date
                    _detailRow("Next Payment", nextPayment),
                    const SizedBox(height: 10),

                    // Status Badge
                    Row(
                      children: [
                        const Text("Status: ", style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPaid ? "Paid" : "Pending",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Buttons
          Row(
  children: [
    // VIEW ORDER Button
    Expanded(
      child: ElevatedButton(
        onPressed: order != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: order!),
                  ),
                );
              }
            : null, // Disabled if no order
        style: ElevatedButton.styleFrom(
          backgroundColor: order != null ? AppColors.primary : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: const Text(
          "View Order",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),

    const SizedBox(width: 16),

    // PAY NOW / PAID Button
    Expanded(
      child: ElevatedButton(
        onPressed: (order != null && !isPaid)
            ? () {
                if (paymentUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentWebView(url: paymentUrl),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Payment link is not available."),
                    ),
                  );
                }
              }
            : null, // Disabled if already paid or no order
        style: ElevatedButton.styleFrom(
          backgroundColor: (order != null && !isPaid)
              ? AppColors.primary
              : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Text(
          isPaid ? "Paid" : "Pay Now",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
)

        ],
      ),
    );
  }

  /// Helper to render a row detail
  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
