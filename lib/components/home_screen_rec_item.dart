import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class HomeScreenRecItem extends StatelessWidget {
  final String title;
  final String imageAsset;

  const HomeScreenRecItem({super.key, required this.title, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 150.0,
          width: 150.0,
          margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imageAsset, fit: BoxFit.cover),
          ),
        ),
        Container(
          width: 150.0,
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.symmetric(horizontal: 15.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
