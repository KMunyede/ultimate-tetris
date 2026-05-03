// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_state.dart';
import 'ui/screens/game_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const TetrisApp(),
    ),
  );
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Tetris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
      ),
      home: const TetrisGame(),
    );
  }
}
