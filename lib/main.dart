import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vespera/screens/common_screen.dart';
import 'package:vespera/screens/signin_screen.dart';
import 'package:vespera/screens/signup_screen.dart';
import 'package:vespera/screens/welcome_screen.dart';
import 'package:vespera/services/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signUp': (context) => const SignUpScreen(),
        '/signIn': (context) => const SignInScreen(),
        '/home': (context) => const CommonScreen(),
      },
    );
  }
}
