import 'package:flutter/material.dart';
import '../game/tetris_engine.dart';
import '../models/piece.dart';
import '../models/tetromino_type.dart';

class TetrisBoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Piece? currentPiece;
  final Piece? ghostPiece;
  final List<int> clearingRows;
  final double animationValue;

  TetrisBoardPainter({
    required this.board,
    required this.currentPiece,
    required this.ghostPiece,
    required this.clearingRows,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / TetrisEngine.columns;
    final double cellHeight = size.height / TetrisEngine.rows;
    final double cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    final double boardWidth = cellSize * TetrisEngine.columns;
    final double boardHeight = cellSize * TetrisEngine.rows;

    // Centering offsets
    final double offsetX = (size.width - boardWidth) / 2;
    final double offsetY = (size.height - boardHeight) / 2;

    // 1. Board background
    final bgRect = Rect.fromLTWH(offsetX, offsetY, boardWidth, boardHeight);
    final bgPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), bgPaint);

    // Subtle grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFF21262D).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int c = 1; c < TetrisEngine.columns; c++) {
      final x = offsetX + c * cellSize;
      canvas.drawLine(Offset(x, offsetY), Offset(x, offsetY + boardHeight), gridPaint);
    }
    for (int r = 1; r < TetrisEngine.rows; r++) {
      final y = offsetY + r * cellSize;
      canvas.drawLine(Offset(offsetX, y), Offset(offsetX + boardWidth, y), gridPaint);
    }

    // 2. Locked blocks on board
    for (int r = 0; r < TetrisEngine.rows; r++) {
      final isClearing = clearingRows.contains(r);
      for (int c = 0; c < TetrisEngine.columns; c++) {
        final color = board[r][c];
        if (color != null) {
          if (isClearing) {
            // Flash white during line clear
            _drawBlock(
              canvas,
              offsetX + c * cellSize,
              offsetY + r * cellSize,
              cellSize,
              Colors.white,
              isGhost: false,
              isFlashing: true,
            );
          } else {
            _drawBlock(
              canvas,
              offsetX + c * cellSize,
              offsetY + r * cellSize,
              cellSize,
              color,
              isGhost: false,
            );
          }
        }
      }
    }

    // 3. Ghost piece (landing guide)
    if (ghostPiece != null && currentPiece != null) {
      final ghostColor = currentPiece!.type.color.withValues(alpha: 0.35);
      for (final block in ghostPiece!.blockPositions) {
        if (block.y >= 0 && block.y < TetrisEngine.rows && block.x >= 0 && block.x < TetrisEngine.columns) {
          _drawBlock(
            canvas,
            offsetX + block.x * cellSize,
            offsetY + block.y * cellSize,
            cellSize,
            ghostColor,
            isGhost: true,
          );
        }
      }
    }

    // 4. Current active piece
    if (currentPiece != null) {
      for (final block in currentPiece!.blockPositions) {
        if (block.y >= 0 && block.y < TetrisEngine.rows && block.x >= 0 && block.x < TetrisEngine.columns) {
          _drawBlock(
            canvas,
            offsetX + block.x * cellSize,
            offsetY + block.y * cellSize,
            cellSize,
            currentPiece!.type.color,
            isGhost: false,
          );
        }
      }
    }

    // 5. Border glow around entire board
    final borderPaint = Paint()
      ..color = const Color(0xFF388BFD).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8)), borderPaint);
  }

  void _drawBlock(
    Canvas canvas,
    double x,
    double y,
    double size,
    Color color, {
    bool isGhost = false,
    bool isFlashing = false,
  }) {
    const double padding = 1.0;
    final rect = Rect.fromLTWH(
      x + padding,
      y + padding,
      size - padding * 2,
      size - padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    if (isGhost) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);
      return;
    }

    if (isFlashing) {
      final flashPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, flashPaint);
      return;
    }

    // Regular styled tetromino block with subtle bevel
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, basePaint);

    // Top-left highlight bevel
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(rect.left + 2, rect.bottom - 2)
      ..lineTo(rect.left + 2, rect.top + 2)
      ..lineTo(rect.right - 2, rect.top + 2);
    canvas.drawPath(path, highlightPaint);

    // Bottom-right shadow bevel
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final shadowPath = Path()
      ..moveTo(rect.left + 3, rect.bottom - 2)
      ..lineTo(rect.right - 2, rect.bottom - 2)
      ..lineTo(rect.right - 2, rect.top + 3);
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant TetrisBoardPainter oldDelegate) {
    return true;
  }
}
