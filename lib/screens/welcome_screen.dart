import 'package:flutter/material.dart';
import 'package:vespera/screens/signin_screen.dart';
import 'package:vespera/screens/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF020D33), Color(0xFF191414)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 200),
                // LOGO & TEXT
                ClipOval(
                  child: Image.asset(
                    'assets/app_icon.jpg',
                    height: 100,
                    width: 100,
                    fit: BoxFit.fill,
                  ),
                ),
                Text(
                  'Millions of songs.\nFree on Vesper.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 00),
                Spacer(),

                // SIGN UP BUTTON
                ElevatedButton(
                  onPressed: () {
                    // Navigate to sign up
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1DA2B9),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    'Sign up for free',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black)],
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // LOG IN BUTTON
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  label: Text('Log In'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
