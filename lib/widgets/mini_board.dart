import 'package:flutter/material.dart';
import '../models/tetromino_type.dart';

class MiniBoard extends StatelessWidget {
  final String title;
  final TetrominoType? pieceType;
  final bool isDimmed;

  const MiniBoard({
    super.key,
    required this.title,
    this.pieceType,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: pieceType == null
                  ? const SizedBox.shrink()
                  : Opacity(
                      opacity: isDimmed ? 0.4 : 1.0,
                      child: CustomPaint(
                        size: const Size(60, 50),
                        painter: _MiniPiecePainter(pieceType: pieceType!),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPiecePainter extends CustomPainter {
  final TetrominoType pieceType;

  _MiniPiecePainter({required this.pieceType});

  @override
  void paint(Canvas canvas, Size size) {
    final points = pieceType.rotations[0];
    const double cellSize = 13.0;

    int minX = 99, maxX = -99, minY = 99, maxY = -99;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final double shapeWidth = (maxX - minX + 1) * cellSize;
    final double shapeHeight = (maxY - minY + 1) * cellSize;
    final double startX = (size.width - shapeWidth) / 2;
    final double startY = (size.height - shapeHeight) / 2;

    for (final p in points) {
      final double x = startX + (p.x - minX) * cellSize;
      final double y = startY + (p.y - minY) * cellSize;
      final rect = Rect.fromLTWH(x + 0.5, y + 0.5, cellSize - 1, cellSize - 1);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));

      final paint = Paint()
        ..color = pieceType.color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);

      // Light edge
      final lightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPiecePainter oldDelegate) {
    return oldDelegate.pieceType != pieceType;
  }
}
