import 'package:flutter/material.dart';

enum SnackBarType { error, success, info }

class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (bg, icon) = switch (type) {
      SnackBarType.error   => (const Color(0xFFEF4444), Icons.error_outline_rounded),
      SnackBarType.success => (const Color(0xFF22C55E), Icons.check_circle_outline_rounded),
      SnackBarType.info    => (const Color(0xFFE8751A), Icons.info_outline_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
        ),
      );
  }

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.error);

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.success, duration: const Duration(seconds: 2));

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.info);
}
