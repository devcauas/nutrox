import 'package:flutter/material.dart';

class AddContent extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const AddContent({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: Colors.black87),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
    );
  }
}
