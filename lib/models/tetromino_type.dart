import 'package:flutter/material.dart';

enum TetrominoType {
  i,
  j,
  l,
  o,
  s,
  t,
  z,
}

extension TetrominoTypeExtension on TetrominoType {
  Color get color {
    switch (this) {
      case TetrominoType.i:
        return const Color(0xFF00E5FF); // Neon Cyan
      case TetrominoType.j:
        return const Color(0xFF2979FF); // Electric Blue
      case TetrominoType.l:
        return const Color(0xFFFF9100); // Neon Orange
      case TetrominoType.o:
        return const Color(0xFFFFD600); // Bright Yellow
      case TetrominoType.s:
        return const Color(0xFF00E676); // Neon Green
      case TetrominoType.t:
        return const Color(0xFFD500F9); // Vivid Purple
      case TetrominoType.z:
        return const Color(0xFFFF1744); // Radiant Red
    }
  }

  Color get darkColor {
    final c = color;
    return HSLColor.fromColor(c)
        .withLightness((HSLColor.fromColor(c).lightness * 0.7).clamp(0.0, 1.0))
        .toColor();
  }

  Color get lightColor {
    final c = color;
    return HSLColor.fromColor(c)
        .withLightness((HSLColor.fromColor(c).lightness * 1.3).clamp(0.0, 1.0))
        .toColor();
  }

  /// 4 rotations for each tetromino type, defined in local coordinate offsets (x, y)
  List<List<PointOffset>> get rotations {
    switch (this) {
      case TetrominoType.i:
        return const [
          [PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1), PointOffset(3, 1)],
          [PointOffset(2, 0), PointOffset(2, 1), PointOffset(2, 2), PointOffset(2, 3)],
          [PointOffset(0, 2), PointOffset(1, 2), PointOffset(2, 2), PointOffset(3, 2)],
          [PointOffset(1, 0), PointOffset(1, 1), PointOffset(1, 2), PointOffset(1, 3)],
        ];
      case TetrominoType.j:
        return const [
          [PointOffset(0, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(1, 1), PointOffset(1, 2)],
          [PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1), PointOffset(2, 2)],
          [PointOffset(1, 0), PointOffset(1, 1), PointOffset(0, 2), PointOffset(1, 2)],
        ];
      case TetrominoType.l:
        return const [
          [PointOffset(2, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(1, 1), PointOffset(1, 2), PointOffset(2, 2)],
          [PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1), PointOffset(0, 2)],
          [PointOffset(0, 0), PointOffset(1, 0), PointOffset(1, 1), PointOffset(1, 2)],
        ];
      case TetrominoType.o:
        return const [
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(1, 1), PointOffset(2, 1)],
        ];
      case TetrominoType.s:
        return const [
          [PointOffset(1, 0), PointOffset(2, 0), PointOffset(0, 1), PointOffset(1, 1)],
          [PointOffset(1, 0), PointOffset(1, 1), PointOffset(2, 1), PointOffset(2, 2)],
          [PointOffset(1, 1), PointOffset(2, 1), PointOffset(0, 2), PointOffset(1, 2)],
          [PointOffset(0, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(1, 2)],
        ];
      case TetrominoType.t:
        return const [
          [PointOffset(1, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(1, 0), PointOffset(1, 1), PointOffset(2, 1), PointOffset(1, 2)],
          [PointOffset(0, 1), PointOffset(1, 1), PointOffset(2, 1), PointOffset(1, 2)],
          [PointOffset(1, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(1, 2)],
        ];
      case TetrominoType.z:
        return const [
          [PointOffset(0, 0), PointOffset(1, 0), PointOffset(1, 1), PointOffset(2, 1)],
          [PointOffset(2, 0), PointOffset(1, 1), PointOffset(2, 1), PointOffset(1, 2)],
          [PointOffset(0, 1), PointOffset(1, 1), PointOffset(1, 2), PointOffset(2, 2)],
          [PointOffset(1, 0), PointOffset(0, 1), PointOffset(1, 1), PointOffset(0, 2)],
        ];
    }
  }

  /// Compact bounding box width/height for preview boxes
  int get previewWidth {
    switch (this) {
      case TetrominoType.i:
        return 4;
      case TetrominoType.o:
        return 2;
      default:
        return 3;
    }
  }
}

class PointOffset {
  final int x;
  final int y;

  const PointOffset(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointOffset &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
