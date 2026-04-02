import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/view/invoice_details.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_providers.dart';
import '../theme/app_color.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? invoice;
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _slide =
        Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(_controller);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login first")),
        );
        Navigator.pop(context);
      });
    } else {
      fetchPendingInvoice(auth.accessToken!);
    }
  }


  Future<void> fetchPendingInvoice(String token) async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.myInvoices),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final List list = body["data"] ?? [];

        final pending = list
            .where((e) => e["status"] == "pending")
            .toList();

        if (pending.isNotEmpty) {
          pending.sort((a, b) =>
              DateTime.parse(b["due_date"])
                  .compareTo(DateTime.parse(a["due_date"])));

          invoice = pending.first;
        } else {
          invoice = null;
        }
      } else {
        invoice = null;
      }
    } catch (e) {
      invoice = null;
      debugPrint("Error: $e");
    }

    setState(() => isLoading = false);

    if (invoice != null) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription",
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoice == null
              ? _emptyUI()
              : _invoiceUI(),
    );
  }

 
  Widget _emptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No Pending Invoice",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Widget _invoiceUI() {
    final bool isPaid = invoice!["status"] == "paid";
    final String invoiceId = invoice!["uuid"];
    final String amount = invoice!["amount_to_pay"];
    final String dueDate = invoice!["due_date"];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Subscription",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

        
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Invoice",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPaid ? "Paid" : "Pending",
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // AMOUNT
                    Text(
                      "TZS $amount",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Due $dueDate",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const Divider(height: 30),

                    _row("Invoice ID", invoiceId),
                    const SizedBox(height: 10),
                    _row("Status", isPaid ? "Paid" : "Pending"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

         
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailScreen(invoice: invoice!),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("View Details", style:TextStyle(color: AppColors.primary),),
                    ),
                  ),

                  const SizedBox(width: 12),

                  
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  //  ROW HELPER
  Widget _row(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}