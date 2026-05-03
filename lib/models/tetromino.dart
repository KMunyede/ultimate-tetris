import 'dart:math';
import 'package:flutter/material.dart';

enum Tetromino {
  I,
  J,
  L,
  O,
  S,
  T,
  Z,
  // Level 3+
  smallT,
  wideL,
  elongatedS, // Remade to 5 pieces
  // Level 6+
  plus,
  longI,
  uShape,
  capitalT // The new perpendicular piece with 3 blocks in both directions (total 5)
}

extension TetrominoExtension on Tetromino {
  Color get color {
    switch (this) {
      case Tetromino.I:
        return const Color(0xFF00F0F0);
      case Tetromino.J:
        return const Color(0xFF0000F0);
      case Tetromino.L:
        return const Color(0xFFF0A000);
      case Tetromino.O:
        return const Color(0xFFF0F000);
      case Tetromino.S:
        return const Color(0xFF00F000);
      case Tetromino.T:
        return const Color(0xFFA000F0);
      case Tetromino.Z:
        return const Color(0xFFF00000);
      case Tetromino.smallT:
        return const Color(0xFFFF69B4);
      case Tetromino.wideL:
        return const Color(0xFFADFF2F);
      case Tetromino.elongatedS:
        return const Color(0xFFFFA500);
      case Tetromino.plus:
        return const Color(0xFFFFFFFF);
      case Tetromino.longI:
        return const Color(0xFF8A2BE2);
      case Tetromino.uShape:
        return const Color(0xFF00BFFF);
      case Tetromino.capitalT:
        return const Color(0xFFDA70D6); // Orchid
    }
  }

  List<Point<int>> get initialPosition {
    switch (this) {
      case Tetromino.I:
        return [Point(3, 0), Point(4, 0), Point(5, 0), Point(6, 0)];
      case Tetromino.J:
        return [Point(3, 0), Point(3, 1), Point(4, 1), Point(5, 1)];
      case Tetromino.L:
        return [Point(3, 1), Point(4, 1), Point(5, 1), Point(5, 0)];
      case Tetromino.O:
        return [Point(4, 0), Point(5, 0), Point(4, 1), Point(5, 1)];
      case Tetromino.S:
        return [Point(3, 1), Point(4, 1), Point(4, 0), Point(5, 0)];
      case Tetromino.T:
        return [Point(3, 1), Point(4, 1), Point(5, 1), Point(4, 0)];
      case Tetromino.Z:
        return [Point(3, 0), Point(4, 0), Point(4, 1), Point(5, 1)];
      case Tetromino.smallT:
        return [Point(4, 0), Point(4, 1), Point(3, 1)];
      case Tetromino.wideL:
        // Was 5 wide base, 1 stalk. 
        // Reducing base by 2 (1 each end) -> 3 wide.
        // Adding 1 to perpendicular -> 2 stalk.
        return [Point(3, 1), Point(4, 1), Point(5, 1), Point(4, 0), Point(4, -1)];
      case Tetromino.elongatedS:
        // Remade to 5 pieces: [3,1], [4,1], [5,1], [4,0], [5,0]
        return [Point(3, 1), Point(4, 1), Point(5, 1), Point(4, 0), Point(5, 0)];
      case Tetromino.plus:
        return [Point(4, 1), Point(4, 0), Point(4, 2), Point(3, 1), Point(5, 1)];
      case Tetromino.longI:
        return [Point(2, 0), Point(3, 0), Point(4, 0), Point(5, 0), Point(6, 0)];
      case Tetromino.uShape:
        return [Point(3, 1), Point(4, 1), Point(5, 1), Point(3, 0), Point(5, 0)];
      case Tetromino.capitalT:
        // Perpendicular piece with 3 blocks wide and 4 blocks tall (added 1 to perpendicular)
        return [Point(3, 2), Point(4, 2), Point(5, 2), Point(4, 1), Point(4, 0), Point(4, -1)];
    }
  }

  List<Point<int>> get previewPoints {
    switch (this) {
      case Tetromino.I:
        return [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0)];
      case Tetromino.J:
        return [Point(0, 0), Point(0, 1), Point(1, 1), Point(2, 1)];
      case Tetromino.L:
        return [Point(0, 1), Point(1, 1), Point(2, 1), Point(2, 0)];
      case Tetromino.O:
        return [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)];
      case Tetromino.S:
        return [Point(0, 1), Point(1, 1), Point(1, 0), Point(2, 0)];
      case Tetromino.T:
        return [Point(0, 1), Point(1, 1), Point(2, 1), Point(1, 0)];
      case Tetromino.Z:
        return [Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)];
      case Tetromino.smallT:
        return [Point(1, 0), Point(1, 1), Point(0, 1)];
      case Tetromino.wideL:
        return [Point(1, 1), Point(2, 1), Point(3, 1), Point(2, 0), Point(2, -1)];
      case Tetromino.elongatedS:
        return [Point(0, 1), Point(1, 1), Point(2, 1), Point(1, 0), Point(2, 0)];
      case Tetromino.plus:
        return [Point(1, 1), Point(1, 0), Point(1, 2), Point(0, 1), Point(2, 1)];
      case Tetromino.longI:
        return [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0), Point(4, 0)];
      case Tetromino.uShape:
        return [Point(0, 1), Point(1, 1), Point(2, 1), Point(0, 0), Point(2, 0)];
      case Tetromino.capitalT:
        return [Point(0, 2), Point(1, 2), Point(2, 2), Point(1, 1), Point(1, 0), Point(1, -1)];
    }
  }
}
