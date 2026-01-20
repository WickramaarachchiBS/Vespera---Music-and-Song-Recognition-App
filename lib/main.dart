import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/providers/whisper_provider.dart';
import 'package:vespera/screens/common_screen.dart';
import 'package:vespera/screens/library_screen.dart';
import 'package:vespera/screens/search_screen.dart';
import 'package:vespera/screens/signin_screen.dart';
import 'package:vespera/screens/signup_screen.dart';
import 'package:vespera/screens/welcome_screen.dart';
import 'package:vespera/screens/whisper_screen_refactored.dart';
import 'package:vespera/services/audio_handler.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/services/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize audio handler for background playback and notifications
  final audioHandler = await audio_service.AudioService.init(
    builder: () => MyAudioHandler(),
    config: const audio_service.AudioServiceConfig(
      androidNotificationChannelId: 'com.vespera.audio',
      androidNotificationChannelName: 'Vespera Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Connect AudioService singleton to the handler
  AudioService().initializeHandler(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WhisperProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      // home: const AuthWrapper(),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/signUp': (context) => const SignUpScreen(),
        '/signIn': (context) => const SignInScreen(),
        '/home': (context) => const CommonScreen(),
        '/search': (context) => const SearchScreen(),
        '/library': (context) => const LibraryScreen(),
        '/whisper': (context) => const WhisperScreen(),
      },
    );
  }
}
