import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info }

class CustomAlert {
  static void show({
    required BuildContext context,
    required AlertType type,
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    Color backgroundColor;
    Color titleColor;
    IconData icon;

    switch (type) {
      case AlertType.success:
        backgroundColor = Colors.green.shade50;
        titleColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case AlertType.error:
        backgroundColor = Colors.red.shade50;
        titleColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      case AlertType.warning:
        backgroundColor = Colors.orange.shade50;
        titleColor = Colors.orange.shade700;
        icon = Icons.warning;
        break;
      case AlertType.info:
        backgroundColor = Colors.blue.shade50;
        titleColor = Colors.blue.shade700;
        icon = Icons.info;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Icon(icon, color: titleColor, size: 32),
          title: Text(
            title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: Text('OK', style: TextStyle(color: titleColor)),
            ),
          ],
        );
      },
    );
  }
}
