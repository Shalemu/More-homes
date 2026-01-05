import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:morehomesapp/theme/app_color.dart';

class PaymentWebView extends StatelessWidget {
  final String url;

  const PaymentWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
