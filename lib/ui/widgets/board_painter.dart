// lib/ui/widgets/board_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/tetromino.dart';

class TetrisPainter extends CustomPainter {
  final List<List<Color?>> board;
  final List<Point<int>> currentPosition;
  final Color currentColor;
  final int columns;
  final int rows;
  final List<int> linesBeingCleared;
  final double clearAnimationProgress;

  TetrisPainter({
    required this.board,
    required this.currentPosition,
    required this.currentColor,
    required this.columns,
    required this.rows,
    this.linesBeingCleared = const [],
    this.clearAnimationProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double blockWidth = size.width / columns;
    double blockHeight = size.height / rows;

    Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= columns; i++) {
      canvas.drawLine(
        Offset(i * blockWidth, 0),
        Offset(i * blockWidth, size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(0, i * blockHeight),
        Offset(size.width, i * blockHeight),
        gridPaint,
      );
    }

    for (int y = 0; y < rows; y++) {
      bool isClearing = linesBeingCleared.contains(y);
      for (int x = 0; x < columns; x++) {
        if (board[y][x] != null) {
          if (isClearing) {
            _drawVaporizingBlock(canvas, x, y, blockWidth, blockHeight, board[y][x]!, clearAnimationProgress);
          } else {
            _drawNeonBlock(canvas, x, y, blockWidth, blockHeight, board[y][x]!);
          }
        }
      }
    }

    // Don't draw ghost or current piece if animating clear
    if (linesBeingCleared.isEmpty) {
      _drawGhostPiece(canvas, blockWidth, blockHeight);

      for (var p in currentPosition) {
        if (p.y >= 0) {
          _drawNeonBlock(canvas, p.x, p.y, blockWidth, blockHeight, currentColor);
        }
      }
    }
  }

  void _drawVaporizingBlock(
    Canvas canvas,
    int x,
    int y,
    double w,
    double h,
    Color color,
    double progress,
  ) {
    // Vaporizing effect: Shrink and fade out
    double scale = 1.0 - progress;
    double opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    double centerX = x * w + w / 2;
    double centerY = y * h + h / 2;
    
    double currentW = w * scale;
    double currentH = h * scale;
    
    Rect rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: currentW - 2,
      height: currentH - 2,
    );

    // Flash white effect at the start
    Color drawColor = progress < 0.2 ? Colors.white : color;

    Paint glowPaint = Paint()
      ..color = drawColor.withValues(alpha: 0.5 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * (1 + progress));
    canvas.drawRect(rect.inflate(4), glowPaint);

    Paint bodyPaint = Paint()..color = drawColor.withValues(alpha: opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      bodyPaint,
    );
  }

  void _drawGhostPiece(Canvas canvas, double w, double h) {
    List<Point<int>> ghostPos = List.from(currentPosition);

    while (!_checkCollision(
      ghostPos.map((p) => Point(p.x, p.y + 1)).toList(),
    )) {
      ghostPos = ghostPos.map((p) => Point(p.x, p.y + 1)).toList();
    }

    Paint ghostPaint = Paint()
      ..color = currentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var p in ghostPos) {
      if (p.y >= 0) {
        canvas.drawRect(
          Rect.fromLTWH(p.x * w + 2, p.y * h + 2, w - 4, h - 4),
          ghostPaint,
        );
      }
    }
  }

  bool _checkCollision(List<Point<int>> position) {
    for (var p in position) {
      if (p.x < 0 || p.x >= columns || p.y >= rows) return true;
      if (p.y >= 0 && board[p.y][p.x] != null) return true;
    }
    return false;
  }

  void _drawNeonBlock(
    Canvas canvas,
    int x,
    int y,
    double w,
    double h,
    Color color,
  ) {
    Rect rect = Rect.fromLTWH(x * w + 1, y * h + 1, w - 2, h - 2);

    Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRect(rect.inflate(2), glowPaint);

    Paint bodyPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      bodyPaint,
    );

    Paint highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRect(
      Rect.fromLTWH(x * w + 3, y * h + 3, w - 8, 3),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TetrisPainter oldDelegate) => true;
}

class NextPiecePainter extends CustomPainter {
  final Tetromino? piece;
  final Color color;

  NextPiecePainter({this.piece, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (piece == null) return;

    double blockSize = size.width / 5;
    List<Point<int>> points = piece!.previewPoints;

    double minX = points.map((p) => p.x.toDouble()).reduce(min);
    double minY = points.map((p) => p.y.toDouble()).reduce(min);
    double maxX = points.map((p) => p.x.toDouble()).reduce(max);
    double maxY = points.map((p) => p.y.toDouble()).reduce(max);

    double pWidth = (maxX - minX + 1) * blockSize;
    double pHeight = (maxY - minY + 1) * blockSize;

    double offsetX = (size.width - pWidth) / 2 - minX * blockSize;
    double offsetY = (size.height - pHeight) / 2 - minY * blockSize;

    Paint paint = Paint()..color = color;
    for (var p in points) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offsetX + p.x * blockSize,
            offsetY + p.y * blockSize,
            blockSize - 2,
            blockSize - 2,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NextPiecePainter oldDelegate) => true;
}
