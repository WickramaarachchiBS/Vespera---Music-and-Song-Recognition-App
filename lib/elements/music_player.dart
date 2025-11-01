import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _sliderValue = 0.3; // Example value

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    // final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Top buttons: Minimize and More
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                    onPressed: () {
                      // This pops the current screen off the navigation stack
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'PLAYING FROM YOUR LIBRARY',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white, size: 30),
                ],
              ),

              // Album Art
              Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/newJeans.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),

              // Song Title and Artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Jeans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('NewJeans', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                    Column(
                      children: [Icon(Icons.add_circle_outline, color: Colors.white, size: 30)],
                    ),
                  ],
                ),
              ),

              // Seek Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 0,
                      max: 1,
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey[700],
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1:21', style: TextStyle(color: Colors.grey)),
                        Text('3:45', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),

              // Player Controls
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.shuffle, color: Colors.grey, size: 30),
                  Icon(Icons.skip_previous, color: Colors.white, size: 40),
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.pause, color: Colors.black, size: 45),
                  ),
                  Icon(Icons.skip_next, color: Colors.white, size: 40),
                  Icon(Icons.repeat, color: Colors.grey, size: 30),
                ],
              ),

              // Bottom Icons
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.speaker_group_outlined, color: Colors.grey),
                  Icon(Icons.share_outlined, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
