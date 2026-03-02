import 'package:flutter/material.dart';
import '../theme/app_color.dart';

enum DialogType { success, error }

class AnimatedMessageDialog extends StatefulWidget {
  final DialogType type;
  final String message;
  final bool redirectToLogin; // new: whether to redirect after success

  const AnimatedMessageDialog({
    super.key,
    required this.type,
    required this.message,
    this.redirectToLogin = false,
  });

  @override
  _AnimatedMessageDialogState createState() => _AnimatedMessageDialogState();
}

class _AnimatedMessageDialogState extends State<AnimatedMessageDialog>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    Color color;

    switch (widget.type) {
      case DialogType.success:
        title = "Success";
        icon = Icons.check_circle;
        color = AppColors.primary; // use app color
        break;
      case DialogType.error:
        title = "Error";
        icon = Icons.error;
        color = AppColors.danger; // use app color
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  if (widget.type == DialogType.success && widget.redirectToLogin) {
                    Navigator.pushReplacementNamed(context, '/login'); // redirect to login
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Ok",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}