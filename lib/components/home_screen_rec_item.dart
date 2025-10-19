import 'package:flutter/material.dart';

class HomeScreenRecItem extends StatelessWidget {
  const HomeScreenRecItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 150.0,
          width: 150.0,
          margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
        ),
        Text('Chill Evening', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
