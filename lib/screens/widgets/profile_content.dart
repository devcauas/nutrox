import 'package:flutter/material.dart';

class ProfileContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ProfileContent({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 3, 155, 109)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap ?? () {},
      ),
    );
  }
}
