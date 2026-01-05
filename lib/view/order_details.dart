import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:morehomesapp/view/help_support_screen.dart';
import 'package:morehomesapp/view/payment_web_view.dart';

/// Premium Order Detail Screen

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

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
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // start
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
    } catch (e) {
      return iso;
    }
  }

  String _formatAmount(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    // Some API returns "1,000.00" already; try to normalize and format nicely
    try {
      final cleaned = raw.replaceAll(',', '').trim();
      final value =
          double.tryParse(cleaned) ??
          double.tryParse(raw.replaceAll(',', '')) ??
          0.0;
      final fr = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
      // If the API provided decimals -> keep two decimals
      if (raw.contains('.') && raw.split('.').last.length > 0) {
        final fr2 = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 2);
        return fr2.format(value);
      }
      return fr.format(value);
    } catch (e) {
      return raw;
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
                        onTap: () =>
                            _copyToClipboard(label.replaceAll(':', ''), value),
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
    final color = isPaid ? const Color.fromARGB(204, 112, 114, 223) : Colors.orange;
    final text = isPaid ? 'PAID' : 'PENDING';
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
      ),
      child: Container(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> order = widget.order;
    final bool isPaid =
        (order['is_paid'] == true) ||
        (order['is_paid']?.toString().toLowerCase() == 'true');
    final String orderId = order['order_id']?.toString() ?? 'N/A';
    final String reference = order['reference']?.toString() ?? 'N/A';
    final String createdAt = order['created_at']?.toString() ?? '';
    final String lastDate = order['last_payment_date']?.toString() ?? '';
    final String nextDate = order['next_payment_date']?.toString() ?? '';
    final String rawAmount = order['amount']?.toString() ?? '';
    final String amount = _formatAmount(rawAmount);
    final int interval = int.tryParse(order['interval']?.toString() ?? '') ?? 0;
    final String paymentUrl = order['payment_gateway_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor:const Color(0xFF1E8F7A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Order Details',
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
                // Header card with gradient & order id + status
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E8F7A), Color(0xFF4BA694)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // left icon / badge
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // title + meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #$orderId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Created: ${_formatDate(createdAt)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // status badge
                      _statusBadge(isPaid),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Details card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                      _rowItem(Icons.schedule, 'Interval:', '$interval days'),
                      const Divider(),
                      _rowItem(
                        Icons.date_range,
                        'Last Payment:',
                        _formatDate(lastDate),
                      ),
                      const Divider(),
                      _rowItem(
                        Icons.calendar_month,
                        'Next Payment:',
                        _formatDate(nextDate),
                        copy: true,
                      ),
                      const Divider(),
                      _rowItem(
                        Icons.info_outline,
                        'Result:',
                        order['result']?.toString() ?? 'N/A',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Pay / Status actions
                if (!isPaid && paymentUrl.isNotEmpty)
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entryController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = _pulseAnim.value;
                            return Transform.scale(
                              scale: scale,
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // open webview payment
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PaymentWebView(url: paymentUrl),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 22,
                                  color: Colors.white,),
                                  label: const Text(
                                    'Pay Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E8F7A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                else
                  // If already paid show small success box
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(0.09)
                          : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid
                            ? Colors.green.withOpacity(0.18)
                            : Colors.grey.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.info_outline,
                          color: isPaid ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPaid
                              ? 'This order has been paid'
                              : 'No payment required',
                          style: TextStyle(
                            color: isPaid
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Help & Support card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Need help with this order?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If you experience any issue with the payment, contact support or open a ticket.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // navigate to support screen 
                                Navigator.push(context, MaterialPageRoute(builder: (_) => HelpSupportScreen()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Open support (not implemented)',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.support_agent_outlined),
                              label: const Text('Contact Support'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _copyToClipboard('Order ID', orderId),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Order ID'),
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
