import 'package:flutter/material.dart';
import 'package:vespera/screens/common_screen.dart';
import 'package:vespera/screens/home_screen.dart';

void main() {
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
      initialRoute: '/',
      routes: {
        '/': (context) => const CommonScreen(),
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const HomeScreen(),
        'library': (context) => const HomeScreen(),
      },
    );
  }
}
