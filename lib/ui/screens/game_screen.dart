// lib/ui/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_state.dart';
import '../widgets/board_painter.dart';
import '../../constants.dart';
import '../../models/tetromino.dart';

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  final FocusNode _focusNode = FocusNode();
  double _horizontalDelta = 0;
  double _verticalDelta = 0;

  // int _tapCount = 0; // Removed to improve rotation latency
  // Timer? _tapTimer; // Removed to improve rotation latency

  @override
  void dispose() {
    _focusNode.dispose();
    // _tapTimer?.cancel();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details, GameState gameState) {
    if (gameState.isGameOver || gameState.isPaused) return;

    _horizontalDelta += details.delta.dx;
    _verticalDelta += details.delta.dy;

    const double effectiveThreshold = 15.0;

    if (_horizontalDelta.abs() > effectiveThreshold) {
      if (_horizontalDelta > 0) {
        gameState.moveRight();
      } else {
        gameState.moveLeft();
      }
      _horizontalDelta = 0;
    }

    if (_verticalDelta > effectiveThreshold) {
      gameState.moveDown();
      _verticalDelta = 0;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _horizontalDelta = 0;
    _verticalDelta = 0;
  }

  void _handleTap(GameState gameState) {
    if (gameState.isPaused) {
      gameState.togglePause();
      return;
    }
    // Immediate rotation for zero latency
    gameState.rotate();
  }

  Future<void> _showQuitDialog(BuildContext context) async {
    final bool? shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Do you want to exit the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldQuit == true) {
      SystemNavigator.pop();
    }
  }

  Future<void> _showHelpDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'HELP & ABOUT',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpSection('CONTROLS', [
                'Swipe Left/Right: Move Piece',
                'Swipe Down: Soft Drop',
                'Double Tap: Hard Drop',
                'Single Tap: Rotate Piece',
                'Triple Tap: Pause/Resume',
              ]),
              const SizedBox(height: 16),
              _helpSection('DIFFICULTY', [
                'Level 1-10: Speed increases every 10 lines cleared.',
                'SRS-Lite: Pieces can "kick" off walls for better rotation.',
                'Lock Delay: 0.5s grace period before piece locks.',
              ]),
              const SizedBox(height: 16),
              _helpSection('ABOUT', [
                'Ultimate Tetris v1.0',
                'A neon-themed retro experience.',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GOT IT', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Widget _helpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Text(
              '• $item',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showQuitDialog(context);
      },
      child: KeyboardListener(
        focusNode: _focusNode..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) gameState.moveLeft();
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) gameState.moveRight();
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) gameState.moveDown();
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) gameState.rotate();
            if (event.logicalKey == LogicalKeyboardKey.space) gameState.hardDrop();
            if (event.logicalKey == LogicalKeyboardKey.keyP) gameState.togglePause();
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Info Bar (Score, Level, Next)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoText('SCORE', '${gameState.score}'),
                      _infoText('LEVEL', '${gameState.level}'),
                      Column(
                        children: [
                          const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white10),
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: CustomPaint(
                                painter: NextPiecePainter(
                                  piece: gameState.nextPiece,
                                  color: gameState.nextPiece?.color ?? Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // Main Gameplay Section (Sidebar + Board)
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -50),
                    child: Row(
                      children: [
                        // Left Side: Sidebar
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _sidebarButton(
                                Icons.refresh,
                                gameState.startGame,
                                label: 'NEW',
                                color: Colors.cyan,
                              ),
                              const SizedBox(height: 24),
                              _sidebarButton(
                                gameState.isPaused ? Icons.play_arrow : Icons.pause,
                                gameState.togglePause,
                                label: 'PAUSE',
                                color: Colors.yellow,
                              ),
                              const SizedBox(height: 24),
                              _sidebarButton(
                                Icons.help_outline,
                                () => _showHelpDialog(context),
                                label: 'HELP',
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AspectRatio(
                              aspectRatio: GameConstants.columns / GameConstants.rows,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: GameConstants.boardBorderColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameConstants.boardBorderColor.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () => _handleTap(gameState),
                                  onDoubleTap: gameState.hardDrop,
                                  onPanUpdate: (details) => _handlePanUpdate(details, gameState),
                                  onPanEnd: _handlePanEnd,
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        painter: TetrisPainter(
                                          board: gameState.board,
                                          currentPosition: gameState.currentPosition,
                                          currentColor: gameState.currentColor,
                                          columns: GameConstants.columns,
                                          rows: GameConstants.rows,
                                          linesBeingCleared: gameState.linesBeingCleared,
                                          clearAnimationProgress: gameState.clearAnimationProgress,
                                        ),
                                        size: Size.infinite,
                                      ),
                                      if (gameState.isPaused)
                                        GestureDetector(
                                          onTap: gameState.togglePause,
                                          child: Container(
                                            color: Colors.black54,
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.pause_circle_filled,
                                                    color: Colors.yellow,
                                                    size: 80,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    'PAUSED',
                                                    style: TextStyle(
                                                      color: Colors.yellow,
                                                      fontSize: 40,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (gameState.isGameOver)
                                        Container(
                                          color: Colors.black87,
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'GAME OVER',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                ElevatedButton(
                                                  onPressed: gameState.startGame,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text(
                                                    'PLAY AGAIN?',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Ergonomic Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, left: 10, right: 10),
                  child: Row(
                    children: [
                      // Left Half: Movement (Left, Down, Right)
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _squareButton(Icons.arrow_back, gameState.moveLeft),
                            _squareButton(Icons.arrow_downward, gameState.moveDown),
                            _squareButton(Icons.arrow_forward, gameState.moveRight),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8), // Minimal center gap

                      // Right Half: Action (Hard Drop, Rotate)
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _squareButton(Icons.keyboard_double_arrow_down, gameState.hardDrop, color: Colors.orange),
                            _squareButton(Icons.rotate_right, gameState.rotate, color: Colors.cyan),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _sidebarButton(IconData icon, VoidCallback onPressed, {required String label, required Color color}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onPressed, {Color color = Colors.white}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: AspectRatio(
          aspectRatio: 1.0, // Ensures square shape
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(icon, color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
