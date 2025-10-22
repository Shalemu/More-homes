import 'package:flutter/material.dart';
import 'package:morehousesapp/theme/app_color.dart';


InputDecoration inputDecoration(
  String label,
  IconData icon, {
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}
