import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/view/order_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backend_apis.dart';


class PaymentHistoryScreen extends StatefulWidget {
  final String? orderId;
    final String? userId;

  const PaymentHistoryScreen({
    super.key,
    this.orderId,
    this.userId,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> payments = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access'); // ✔ Correct token key

      if (token == null || token.isEmpty) {
        setState(() {
          message = "Access token not found. Please login again.";
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse(ApiConstants.paymentHistory);
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        payments = data["data"] ?? [];

        setState(() {
          isLoading = false;
          message = payments.isEmpty ? "No payments found." : '';
        });
      } else {
        setState(() {
          message =
              'Failed to load payment history. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error loading payment history: $e';
        isLoading = false;
      });
    }
  }

  Future<void> viewOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again.")),
      );
      return;
    }

    final url = Uri.parse(ApiConstants.paymentUrl);
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      if (jsonBody["data"] == null || jsonBody["data"].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active order found.")),
        );
        return;
      }

      final order = jsonBody["data"][0];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load order: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Payment History"
            , style: TextStyle(color:Colors.white),),
        backgroundColor: const Color(0xFF1E8F7A),
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
                          backgroundColor: const Color(0xFF1E8F7A),
                        ),
                        child: const Text("View Order",
                        style: TextStyle(color:Colors.white),),
                      )
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
                    );
                  },
                ),
    );
  }
}
