import 'package:flutter/material.dart';

class TopNotification {
  static void show(
    BuildContext context, {
    required String message,
    required Color color,
    IconData icon = Icons.info_outline,
    int seconds = 2,
  }) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _NotificationCard(
            message: message,
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