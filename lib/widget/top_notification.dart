import 'package:flutter/material.dart';

class TopNotification {
  static void show(
    BuildContext context, {
    required String? message,
    required Color color,
    IconData icon = Icons.info_outline,
    int seconds = 3,
  }) {
    // 🔥 NEVER show empty or null message
    final text = (message == null || message.trim().isEmpty)
        ? "Something went wrong"
        : message;

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _NotificationCard(
            message: text,
            color: color,
            icon: icon,
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(Duration(seconds: seconds), () {
      entry.remove();
    });
  }

  // 🔥 SUCCESS MESSAGE
  static void success(BuildContext context, String? message) {
    show(
      context,
      message: message,
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }

  // 🔥 ERROR MESSAGE
  static void error(BuildContext context, String? message) {
    show(
      context,
      message: message,
      color: Colors.red,
      icon: Icons.error,
    );
  }


  static void update(BuildContext context, String? message) {
    show(
      context,
      message: message,
      color: Colors.orange,
      icon: Icons.system_update,
      seconds: 5,
    );
  }


  static void fromApi(
    BuildContext context,
    String? msg, {
    int statusCode = 0,
    bool? forceUpdate,
  }) {
    // 1. FORCE UPDATE FIRST
    if (forceUpdate == true ||
        (msg ?? '').toLowerCase().contains("update")) {
      update(context, msg ?? "Please update your application");
      return;
    }

    // 2. ERROR
    if (statusCode != 200) {
      error(context, msg);
      return;
    }

    // 3. DEFAULT INFO
    show(
      context,
      message: msg,
      color: Colors.blue,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _NotificationCard({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}