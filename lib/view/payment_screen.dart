import 'package:flutter/material.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/services/payment_service.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class PaymentScreen extends StatefulWidget {
  final String planId;
  final String invoiceId;

  const PaymentScreen({super.key, required this.planId, required this.invoiceId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _service = PaymentService();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

Future<void> _pay() async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final phone = phoneController.text.trim();

  if (phone.length < 9) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      text: "Enter valid phone number",
    );
    return;
  }

  setState(() => isLoading = true);

  try {

    final result = await _service.subscribe(
      token: auth.accessToken!,
      planUuid: widget.planId,
    );

    if (result["success"] != true) {
      QuickAlert.show(
        // ignore: use_build_context_synchronously
        context: context,
        type: QuickAlertType.error,
        text: result["message"] ?? "Subscription failed",
      );
      return;
    }

   
    final String? invoiceUuid = result["invoice_uuid"];

    if (invoiceUuid == null || invoiceUuid.isEmpty) {
      QuickAlert.show(
        // ignore: use_build_context_synchronously
        context: context,
        type: QuickAlertType.error,
        text: "Invoice UUID missing",
      );
      return;
    }

    /// =========================
    /// STEP 2: MAKE PAYMENT
    /// =========================
    await _service.makePayment(
      token: auth.accessToken!,
      invoiceUuid: invoiceUuid,
      phone: phone,
    );

    if (!mounted) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: "Payment request sent to $phone",
    );
  } catch (e) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      text: "Payment failed: $e",
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Enter Mobile Number",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "e.g 255712345678",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}