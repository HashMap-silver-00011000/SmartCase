import 'package:metro_gps/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final normalized = role.toLowerCase();
    final color = switch (normalized) {
      'admin' => AppColors.admin,
      'conductor' => AppColors.driver,
      _ => AppColors.passenger,
    };
    return Chip(
      label: Text(role.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}
