import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class HomeScreenLibItem extends StatelessWidget {
  const HomeScreenLibItem({super.key, required this.screenHeight, required this.screenWidth});

  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (screenHeight * 0.1) - 30,
      width: (screenWidth * 0.5) - 20,
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset('assets/newJeans.jpg'),
          ),
          SizedBox(width: 10.0),
          Text('Playlist Name', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
