import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/core/app_dialog.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/view/changePlan_screen.dart';
import 'package:morehomesapp/view/help_support_screen.dart';
import 'package:morehomesapp/view/payment_screen.dart';
import 'package:provider/provider.dart';

/// Premium Invoice Detail Screen (UI unchanged)

class InvoiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _entryController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatAmount(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final cleaned = raw.replaceAll(',', '');
      final value = double.tryParse(cleaned) ?? 0.0;

      final fr = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
      return fr.format(value);
    } catch (_) {
      return raw;
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _rowItem(
    IconData icon,
    String label,
    String value, {
    bool copy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1E8F7A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (copy)
                      GestureDetector(
                        onTap: () => _copyToClipboard(label, value),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8F7A).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Color(0xFF1E8F7A),
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
    );
  }

  Widget _statusBadge(bool isPaid) {
    final color = isPaid ? Colors.green : Colors.orange;
    final text = isPaid ? 'PAID' : 'PENDING';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.hourglass_top,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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

        // fetchInvoices();
      } else {
        AppDialog.error(context, message: data["detail"] ?? "Payment failed");
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      AppDialog.error(context, message: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> invoice = widget.invoice;

    final bool isPaid = (invoice['status']?.toString().toLowerCase() == 'paid');

    final String orderId = invoice['uuid']?.toString() ?? 'N/A';

    final String reference = invoice['reference']?.toString() ?? 'N/A';

    final String createdAt = invoice['due_date']?.toString() ?? '';

    final String rawAmount =
        invoice['amount_to_pay']?.toString() ??
        invoice['amount']?.toString() ??
        '';

    final String amount = _formatAmount(rawAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E8F7A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Invoice Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER (UNCHANGED UI)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E8F7A), Color(0xFF4BA694)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.receipt_long,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice #$orderId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Due: ${_formatDate(createdAt)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(isPaid),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // DETAILS (UNCHANGED UI)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _rowItem(
                        Icons.vpn_key,
                        'Reference:',
                        reference,
                        copy: true,
                      ),
                      const Divider(),

                      _rowItem(Icons.attach_money, 'Amount:', amount),
                      const Divider(),

                      _rowItem(
                        Icons.calendar_month,
                        'Due Date:',
                        _formatDate(createdAt),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Column(
  crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 FULL WIDTH
  children: [
    // =========================
    // PAY / PAID STATE
    // =========================
    if (!isPaid)
      ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Curves.easeOut,
          ),
        ),
        child: SizedBox(
          height: 56,
          width: double.infinity, // 👈 FORCE FULL WIDTH
          child: ElevatedButton.icon(
            onPressed: () {
              AppDialog.payment(
                context,
                invoiceId: invoice["uuid"].toString(),
                onPay: (phone) {
                  _initiatePayment(
                    invoice["uuid"].toString(),
                    phone,
                  );
                },
              );
            },
            icon: const Icon(Icons.payment, color: Colors.white),
            label: const Text(
              'Pay Now',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8F7A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      )
    else
      Container(
        height: 56, // 👈 SAME HEIGHT AS BUTTON
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              "Invoice Paid",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),

    const SizedBox(height: 12),

    // =========================
    // CHANGE PLAN (ALWAYS)
    // =========================
    SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChangeplanScreen(), // keep simple
            ),
          );
        },
        icon: const Icon(Icons.swap_horiz),
        label: const Text("Change Plan"),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),

    const SizedBox(height: 24),
  ],
),
                const SizedBox(height: 24),

                // SUPPORT
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Need help with this order?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HelpSupportScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.support_agent_outlined),
                              label: const Text('Support'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _copyToClipboard('Order ID', orderId),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy ID'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            
            ),
          ),
        ),
      ),
    );
  }
}
