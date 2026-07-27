import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

class SnackBarHelper {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        iconData = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade600;
        iconData = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade700;
        iconData = Icons.warning_amber_outlined;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue.shade600;
        iconData = Icons.info_outline;
        if (message.contains("Por favor, selecione a data de nascimento.")) {
          backgroundColor = Colors.white;
          textColor = Colors.black;
          iconData = Icons.calendar_today_outlined;
        }
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: textColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}