import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/top_list_group.dart';
import 'package:vespera/models/top_item.dart';

class TopListCard extends StatelessWidget {
  final String title;
  final List<TopItem> thisWeekItems;
  final List<TopItem> allTimeItems;

  const TopListCard({
    required this.title,
    required this.thisWeekItems,
    required this.allTimeItems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TopListGroup(label: 'This week', items: thisWeekItems),
          const SizedBox(height: 6),
          TopListGroup(label: 'All-time', items: allTimeItems),
        ],
      ),
    );
  }
}
