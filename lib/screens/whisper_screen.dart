import 'package:flutter/material.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Whisper Screen'));
  }
}
