// lib/providers/game_state.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../constants.dart';

class GameState extends ChangeNotifier {
  List<List<Color?>> board = List.generate(
    GameConstants.rows,
    (_) => List.filled(GameConstants.columns, null),
  );

  late Tetromino currentPiece;
  late List<Point<int>> currentPosition;
  late Color currentColor;
  Tetromino? nextPiece;

  Timer? _gameTimer;
  Timer? _lockDelayTimer;
  bool isGameOver = false;
  bool isPaused = false;
  int score = 0;
  int level = 1;
  int linesClearedTotal = 0;
  bool isLocking = false;
  
  // Animation state
  List<int> linesBeingCleared = [];
  double clearAnimationProgress = 0.0;
  bool isAnimatingClear = false;

  GameState() {
    _initGame();
  }

  void _initGame() {
    _spawnNextPiece();
    spawnPiece();
    _startTimer();
  }

  void _spawnNextPiece() {
    // Difficulty Levels:
    // Level 1-2: Standard 7 Tetrominos
    // Level 3-5: Adds 3 pieces (smallT, wideL, elongatedS) -> Total 10
    // Level 6+: Adds 4 more (plus, longI, uShape, capitalT) -> Total 14
    int maxIndex;
    if (level >= 6) {
      maxIndex = 14;
    } else if (level >= 3) {
      maxIndex = 10;
    } else {
      maxIndex = 7;
    }
    nextPiece = Tetromino.values[Random().nextInt(maxIndex)];
  }

  void startGame() {
    board = List.generate(
      GameConstants.rows,
      (_) => List.filled(GameConstants.columns, null),
    );
    score = 0;
    level = 1;
    linesClearedTotal = 0;
    isGameOver = false;
    isPaused = false;
    spawnPiece();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    int speed = GameConstants.getSpeed(level);
    _gameTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (!isPaused && !isGameOver) {
        moveDown();
      }
    });
  }

  void spawnPiece() {
    currentPiece = nextPiece!;
    _spawnNextPiece();

    currentColor = currentPiece.color;
    currentPosition = currentPiece.initialPosition;

    if (checkCollision(currentPosition)) {
      isGameOver = true;
      _gameTimer?.cancel();
    }
    notifyListeners();
  }

  void moveDown() {
    if (isGameOver || isPaused || isAnimatingClear) return;

    List<Point<int>> nextPos = currentPosition
        .map((p) => Point(p.x, p.y + 1))
        .toList();
    if (checkCollision(nextPos)) {
      if (!isLocking) {
        _startLockDelay();
      }
    } else {
      currentPosition = nextPos;
      if (isLocking) {
        _cancelLockDelay();
      }
      notifyListeners();
    }
  }

  void _startLockDelay() {
    isLocking = true;
    _lockDelayTimer?.cancel();
    _lockDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (isLocking) {
        placePiece();
      }
    });
  }

  void _cancelLockDelay() {
    isLocking = false;
    _lockDelayTimer?.cancel();
  }

  void moveLeft() {
    if (isGameOver || isPaused || isAnimatingClear) return;
    List<Point<int>> nextPos = currentPosition
        .map((p) => Point(p.x - 1, p.y))
        .toList();
    if (!checkCollision(nextPos)) {
      currentPosition = nextPos;
      if (isLocking) {
        _startLockDelay();
      }
      notifyListeners();
    }
  }

  void moveRight() {
    if (isGameOver || isPaused || isAnimatingClear) return;
    List<Point<int>> nextPos = currentPosition
        .map((p) => Point(p.x + 1, p.y))
        .toList();
    if (!checkCollision(nextPos)) {
      currentPosition = nextPos;
      if (isLocking) {
        _startLockDelay();
      }
      notifyListeners();
    }
  }

  void rotate() {
    if (isGameOver || isPaused || isAnimatingClear || currentPiece == Tetromino.O) return;

    Point<int> pivot = currentPosition[1];
    List<Point<int>> nextPos = currentPosition.map((p) {
      int relativeX = p.x - pivot.x;
      int relativeY = p.y - pivot.y;
      return Point(pivot.x - relativeY, pivot.y + relativeX);
    }).toList();

    if (checkCollision(nextPos)) {
      List<Point<int>> kicks = [
        const Point(-1, 0),
        const Point(1, 0),
        const Point(0, -1),
        const Point(-1, -1),
        const Point(1, -1),
        const Point(-2, 0),
        const Point(2, 0),
      ];

      bool kicked = false;
      for (var kick in kicks) {
        var kickedPos = nextPos.map((p) => Point(p.x + kick.x, p.y + kick.y)).toList();
        if (!checkCollision(kickedPos)) {
          nextPos = kickedPos;
          kicked = true;
          break;
        }
      }

      if (!kicked) return;
    }

    currentPosition = nextPos;
    if (isLocking) {
      _startLockDelay();
    }
    notifyListeners();
  }

  void hardDrop() {
    if (isGameOver || isPaused) return;
    while (!checkCollision(
      currentPosition.map((p) => Point(p.x, p.y + 1)).toList(),
    )) {
      currentPosition = currentPosition
          .map((p) => Point(p.x, p.y + 1))
          .toList();
    }
    _cancelLockDelay();
    placePiece();
  }

  bool checkCollision(List<Point<int>> position) {
    for (var p in position) {
      if (p.x < 0 || p.x >= GameConstants.columns || p.y >= GameConstants.rows) {
        return true;
      }
      if (p.y >= 0 && board[p.y][p.x] != null) {
        return true;
      }
    }
    return false;
  }

  void placePiece() {
    _cancelLockDelay();
    for (var p in currentPosition) {
      if (p.y >= 0) {
        board[p.y][p.x] = currentColor;
      }
    }
    _clearLines();
    if (!isAnimatingClear) {
      spawnPiece();
    }
    notifyListeners();
  }

  void _clearLines() {
    List<int> linesToClear = [];
    for (int y = GameConstants.rows - 1; y >= 0; y--) {
      bool full = true;
      for (int x = 0; x < GameConstants.columns; x++) {
        if (board[y][x] == null) {
          full = false;
          break;
        }
      }
      if (full) {
        linesToClear.add(y);
      }
    }

    if (linesToClear.isNotEmpty) {
      _startClearAnimation(linesToClear);
    }
  }

  void _startClearAnimation(List<int> lines) {
    isAnimatingClear = true;
    linesBeingCleared = lines;
    clearAnimationProgress = 0.0;
    
    // Pause main game timer during animation
    _gameTimer?.cancel();

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      clearAnimationProgress += 0.05; // ~300ms animation
      if (clearAnimationProgress >= 1.0) {
        timer.cancel();
        _finalizeLineClear();
      }
      notifyListeners();
    });
  }

  void _finalizeLineClear() {
    int linesCount = linesBeingCleared.length;
    
    // Sort lines in descending order (bottom to top)
    linesBeingCleared.sort((a, b) => b.compareTo(a));

    // Remove rows from bottom to top to maintain index integrity
    for (int y in linesBeingCleared) {
      board.removeAt(y);
    }
    
    // Add new empty rows at the top for every row removed
    for (int i = 0; i < linesCount; i++) {
      board.insert(0, List.filled(GameConstants.columns, null));
    }

    linesClearedTotal += linesCount;
    score += GameConstants.calculateScore(linesCount, level);
    int newLevel = (linesClearedTotal ~/ 10) + 1;
    if (newLevel != level) {
      level = newLevel;
    }
    
    isAnimatingClear = false;
    linesBeingCleared = [];
    clearAnimationProgress = 0.0;
    
    // Check for lines again in case the drop formed new ones (Cascading Clear)
    _clearLines();
    
    if (!isAnimatingClear) {
      _startTimer(); // Resume gravity
      spawnPiece(); // Spawn next piece
    }
    notifyListeners();
  }

  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _lockDelayTimer?.cancel();
    super.dispose();
  }
}
