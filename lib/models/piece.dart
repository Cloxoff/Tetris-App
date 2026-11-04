import 'tetromino_type.dart';

class Piece {
  final TetrominoType type;
  final int rotation;
  final int x;
  final int y;

  const Piece({
    required this.type,
    this.rotation = 0,
    required this.x,
    required this.y,
  });

  /// Get the actual board positions of this piece's 4 blocks
  List<PointOffset> get blockPositions {
    final localPoints = type.rotations[rotation % 4];
    return localPoints.map((p) => PointOffset(p.x + x, p.y + y)).toList();
  }

  Piece moveBy(int dx, int dy) {
    return Piece(
      type: type,
      rotation: rotation,
      x: x + dx,
      y: y + dy,
    );
  }

  Piece rotateClockwise() {
    return Piece(
      type: type,
      rotation: (rotation + 1) % 4,
      x: x,
      y: y,
    );
  }

  Piece rotateCounterClockwise() {
    return Piece(
      type: type,
      rotation: (rotation + 3) % 4,
      x: x,
      y: y,
    );
  }

  Piece copyWith({
    TetrominoType? type,
    int? rotation,
    int? x,
    int? y,
  }) {
    return Piece(
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}
