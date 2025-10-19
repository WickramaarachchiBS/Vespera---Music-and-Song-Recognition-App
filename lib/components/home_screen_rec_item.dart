import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class HomeScreenRecItem extends StatelessWidget {
  const HomeScreenRecItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 150.0,
          width: 150.0,
          margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/her.jpg'),
          ),
        ),
        Container(
          width: 150.0,
          alignment: Alignment.centerLeft,
          child: Text(
            'Chill Evening',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
