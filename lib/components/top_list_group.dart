import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/top_item.dart';

class TopListGroup extends StatelessWidget {
  final String label;
  final List<TopItem> items;

  const TopListGroup({required this.label, required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          const Text(
            'No data yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          )
        else
          ...items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${entry.key + 1}. ${entry.value.label} (${entry.value.count})',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ),
      ],
    );
  }
}
