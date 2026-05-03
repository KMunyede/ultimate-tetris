import 'package:flutter/material.dart';

class GameConstants {
  static const int columns = 10;
  static const int rows = 20;

  static const Color backgroundColor = Color(0xFF050505);
  static const Color boardBorderColor = Color(0x4D00FFFF); // Cyan with opacity
  static const Color gridLineColor = Color(
    0x0DFFFFFF,
  ); // White with very low opacity

  static int calculateScore(int lines, int level) {
    switch (lines) {
      case 1:
        return 100 * level;
      case 2:
        return 300 * level;
      case 3:
        return 500 * level;
      case 4:
        return 800 * level;
      default:
        return 0;
    }
  }

  static int getSpeed(int level) {
    // Professional speed scaling:
    // Level 1: 800ms
    // Level 3: 600ms (Special pieces added)
    // Level 6: 300ms (Advanced pieces added - Speed increases!)
    // Caps at 100ms for Level 10+
    if (level >= 10) return 100;
    
    // Smooth geometric progression
    // Starts at 800 and decreases faster as level goes up
    int baseSpeed = 800;
    for (int i = 1; i < level; i++) {
      if (i < 3) {
        baseSpeed -= 100; // L1->L2, L2->L3: -100ms
      } else if (i < 6) {
        baseSpeed -= 80;  // L3->L4, L4->L5, L5->L6: -80ms
      } else {
        baseSpeed -= 50;  // L6+: -50ms
      }
    }
    return baseSpeed.clamp(100, 800);
  }
}
