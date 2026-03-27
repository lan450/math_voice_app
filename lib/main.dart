import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MathVoiceApp());
}

class MathVoiceApp extends StatelessWidget {
  const MathVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '口算训练',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
