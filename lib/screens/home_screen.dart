import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/home_screen_lib_item.dart';
import 'package:vespera/components/home_screen_rec_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
        ),
        actions: [
          IconButton(
            //USE A CUSTOM ICON FOR THIS
            icon: const Icon(Icons.settings, size: 30, color: AppColors.textPrimary),
            // Handle settings button press
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                children: [
                  //LIBRARY ITEMS MUST BE AUTOMATED ACCORDING TO NO.OF PLAYLISTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.0),
            // TEXT FOR RECOMMENDED ITEMS
            Container(
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(left: 18.0),
              child: Text(
                'More of what you like',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // RECOMMENDATION ITEMS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(children: [HomeScreenRecItem(), HomeScreenRecItem(), HomeScreenRecItem()]),
                ],
              ),
            ),
            SizedBox(height: 10.0),
            // TEXT FOR RECENT PLAYLIST ITEMS
            Container(
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(left: 18.0),
              child: Text(
                'Recent Playlists',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // RECOMMENDATION ITEMS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(children: [HomeScreenRecItem(), HomeScreenRecItem(), HomeScreenRecItem()]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
