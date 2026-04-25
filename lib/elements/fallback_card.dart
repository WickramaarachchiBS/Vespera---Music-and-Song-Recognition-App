import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class FallbackCard extends StatelessWidget {
  final String message;

  const FallbackCard({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
