import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tetromino_type.dart';
import '../models/piece.dart';
import '../services/high_score_service.dart';

enum GameState {
  ready,
  playing,
  paused,
  gameOver,
}

class TetrisEngine extends ChangeNotifier {
  static const int columns = 10;
  static const int rows = 20;

  // Board matrix: board[row][col]
  late List<List<Color?>> board;

  Piece? currentPiece;
  TetrominoType? holdPiece;
  bool canHold = true;

  final List<TetrominoType> _bag = [];
  final List<TetrominoType> nextPieces = [];

  int score = 0;
  int lines = 0;
  int level = 1;
  int highScore = 0;
  int combo = -1;

  GameState state = GameState.ready;
  List<int> clearingRows = [];
  bool hapticsEnabled = true;

  Timer? _gameLoopTimer;
  Timer? _lockDelayTimer;
  bool _isLocking = false;

  final Random _random = Random();

  TetrisEngine() {
    _initBoard();
    _loadHighScore();
  }

  void _initBoard() {
    board = List.generate(rows, (_) => List.filled(columns, null));
  }

  Future<void> _loadHighScore() async {
    highScore = await HighScoreService.getHighScore();
    notifyListeners();
  }

  void startGame() {
    _initBoard();
    score = 0;
    lines = 0;
    level = 1;
    combo = -1;
    holdPiece = null;
    canHold = true;
    clearingRows.clear();
    _bag.clear();
    nextPieces.clear();

    _fillBagIfNeeded();
    while (nextPieces.length < 4) {
      nextPieces.add(_drawFromBag());
    }

    state = GameState.playing;
    _spawnNextPiece();
    _startTimer();
    _triggerHaptic(HapticFeedbackType.medium);
    notifyListeners();
  }

  void pauseGame() {
    if (state != GameState.playing) return;
    state = GameState.paused;
    _cancelTimers();
    notifyListeners();
  }

  void resumeGame() {
    if (state != GameState.paused) return;
    state = GameState.playing;
    _startTimer();
    notifyListeners();
  }

  void togglePause() {
    if (state == GameState.playing) {
      pauseGame();
    } else if (state == GameState.paused) {
      resumeGame();
    }
  }

  void toggleHaptics() {
    hapticsEnabled = !hapticsEnabled;
    if (hapticsEnabled) {
      _triggerHaptic(HapticFeedbackType.light);
    }
    notifyListeners();
  }

  // --- BAG & SPAWN ---

  void _fillBagIfNeeded() {
    if (_bag.isEmpty) {
      final types = List<TetrominoType>.from(TetrominoType.values);
      types.shuffle(_random);
      _bag.addAll(types);
    }
  }

  TetrominoType _drawFromBag() {
    _fillBagIfNeeded();
    return _bag.removeAt(0);
  }

  void _spawnNextPiece() {
    _cancelLockTimer();
    final type = nextPieces.removeAt(0);
    nextPieces.add(_drawFromBag());

    // Spawn centered horizontally at top
    final spawnX = (columns - type.previewWidth) ~/ 2;
    final piece = Piece(
      type: type,
      rotation: 0,
      x: spawnX,
      y: 0,
    );

    if (!_isValidPosition(piece)) {
      // Immediate collision means Game Over!
      _gameOver();
      return;
    }

    currentPiece = piece;
    canHold = true;
    notifyListeners();
  }

  // --- GHOST PIECE ---

  Piece? get ghostPiece {
    if (currentPiece == null || state != GameState.playing) return null;
    var ghost = currentPiece!;
    while (_isValidPosition(ghost.moveBy(0, 1))) {
      ghost = ghost.moveBy(0, 1);
    }
    return ghost;
  }

  // --- CONTROLS ---

  bool moveLeft() {
    if (state != GameState.playing || currentPiece == null) return false;
    final target = currentPiece!.moveBy(-1, 0);
    if (_isValidPosition(target)) {
      currentPiece = target;
      _onPieceShifted();
      _triggerHaptic(HapticFeedbackType.selection);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool moveRight() {
    if (state != GameState.playing || currentPiece == null) return false;
    final target = currentPiece!.moveBy(1, 0);
    if (_isValidPosition(target)) {
      currentPiece = target;
      _onPieceShifted();
      _triggerHaptic(HapticFeedbackType.selection);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool softDrop() {
    if (state != GameState.playing || currentPiece == null) return false;
    final target = currentPiece!.moveBy(0, 1);
    if (_isValidPosition(target)) {
      currentPiece = target;
      score += 1;
      _triggerHaptic(HapticFeedbackType.selection);
      notifyListeners();
      return true;
    } else {
      _lockPiece();
      return false;
    }
  }

  void hardDrop() {
    if (state != GameState.playing || currentPiece == null) return;
    var dropped = currentPiece!;
    int dropDistance = 0;

    while (_isValidPosition(dropped.moveBy(0, 1))) {
      dropped = dropped.moveBy(0, 1);
      dropDistance++;
    }

    currentPiece = dropped;
    score += dropDistance * 2;
    _triggerHaptic(HapticFeedbackType.heavy);
    _lockPiece();
  }

  bool rotateClockwise() {
    if (state != GameState.playing || currentPiece == null) return false;
    return _applyRotation(currentPiece!.rotateClockwise());
  }

  bool rotateCounterClockwise() {
    if (state != GameState.playing || currentPiece == null) return false;
    return _applyRotation(currentPiece!.rotateCounterClockwise());
  }

  bool _applyRotation(Piece rotated) {
    // Standard wall kicks test offsets
    const kickOffsets = [
      PointOffset(0, 0),
      PointOffset(-1, 0),
      PointOffset(1, 0),
      PointOffset(0, -1),
      PointOffset(-2, 0),
      PointOffset(2, 0),
      PointOffset(-1, -1),
      PointOffset(1, -1),
    ];

    for (final offset in kickOffsets) {
      final testPiece = rotated.moveBy(offset.x, offset.y);
      if (_isValidPosition(testPiece)) {
        currentPiece = testPiece;
        _onPieceShifted();
        _triggerHaptic(HapticFeedbackType.light);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void hold() {
    if (state != GameState.playing || currentPiece == null || !canHold) return;

    _cancelLockTimer();
    final currentType = currentPiece!.type;

    if (holdPiece == null) {
      holdPiece = currentType;
      _spawnNextPiece();
    } else {
      final prevHold = holdPiece!;
      holdPiece = currentType;
      final spawnX = (columns - prevHold.previewWidth) ~/ 2;
      final piece = Piece(
        type: prevHold,
        rotation: 0,
        x: spawnX,
        y: 0,
      );
      if (_isValidPosition(piece)) {
        currentPiece = piece;
      } else {
        _gameOver();
        return;
      }
    }

    canHold = false;
    _triggerHaptic(HapticFeedbackType.medium);
    notifyListeners();
  }

  // --- COLLISION CHECKING ---

  bool _isValidPosition(Piece piece) {
    for (final block in piece.blockPositions) {
      if (block.x < 0 || block.x >= columns) return false;
      if (block.y >= rows) return false;
      if (block.y >= 0 && board[block.y][block.x] != null) return false;
    }
    return true;
  }

  // --- LOCKING & DELAY ---

  void _onPieceShifted() {
    if (_isLocking) {
      // If piece moved while touching ground, extend lock delay briefly
      _startLockTimer();
    }
  }

  void _startLockTimer() {
    _cancelLockTimer();
    _isLocking = true;
    _lockDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (state == GameState.playing && currentPiece != null) {
        if (!_isValidPosition(currentPiece!.moveBy(0, 1))) {
          _lockPiece();
        } else {
          _isLocking = false;
        }
      }
    });
  }

  void _cancelLockTimer() {
    _lockDelayTimer?.cancel();
    _lockDelayTimer = null;
    _isLocking = false;
  }

  void _lockPiece() {
    _cancelLockTimer();
    if (currentPiece == null) return;

    for (final block in currentPiece!.blockPositions) {
      if (block.y >= 0 && block.y < rows && block.x >= 0 && block.x < columns) {
        board[block.y][block.x] = currentPiece!.type.color;
      } else if (block.y < 0) {
        _gameOver();
        return;
      }
    }

    currentPiece = null;
    _checkLineClears();
  }

  // --- LINE CLEARING & SCORING ---

  void _checkLineClears() {
    final fullRows = <int>[];
    for (int r = 0; r < rows; r++) {
      if (board[r].every((cell) => cell != null)) {
        fullRows.add(r);
      }
    }

    if (fullRows.isEmpty) {
      combo = -1;
      _spawnNextPiece();
      return;
    }

    // Line clearing animation
    clearingRows = List<int>.from(fullRows);
    _cancelTimers();
    _triggerHaptic(HapticFeedbackType.heavy);
    notifyListeners();

    // After animation delay, collapse rows
    Future.delayed(const Duration(milliseconds: 180), () {
      if (state != GameState.playing) return;

      for (final r in fullRows) {
        board.removeAt(r);
        board.insert(0, List.filled(columns, null));
      }

      clearingRows.clear();
      combo++;

      final clearedCount = fullRows.length;
      lines += clearedCount;

      // Classic scoring system
      int lineScore = 0;
      switch (clearedCount) {
        case 1:
          lineScore = 100 * level;
          break;
        case 2:
          lineScore = 300 * level;
          break;
        case 3:
          lineScore = 500 * level;
          break;
        case 4:
          lineScore = 800 * level; // Tetris!
          break;
      }

      final comboBonus = combo > 0 ? combo * 50 * level : 0;
      score += lineScore + comboBonus;

      // Level progression every 10 lines
      final newLevel = (lines ~/ 10) + 1;
      if (newLevel > level) {
        level = newLevel;
        _triggerHaptic(HapticFeedbackType.heavy);
      }

      if (score > highScore) {
        highScore = score;
        HighScoreService.saveHighScore(highScore);
      }

      _spawnNextPiece();
      _startTimer();
      notifyListeners();
    });
  }

  // --- GAME OVER & LOOP ---

  void _gameOver() {
    state = GameState.gameOver;
    _cancelTimers();
    if (score > highScore) {
      highScore = score;
      HighScoreService.saveHighScore(highScore);
    }
    _triggerHaptic(HapticFeedbackType.heavy);
    notifyListeners();
  }

  Duration get _tickInterval {
    // Smooth speed curve based on level
    final ms = max(90, 800 - (level - 1) * 75);
    return Duration(milliseconds: ms);
  }

  void _startTimer() {
    _cancelTimers();
    _gameLoopTimer = Timer.periodic(_tickInterval, (timer) {
      _tick();
    });
  }

  void _cancelTimers() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
    _cancelLockTimer();
  }

  void _tick() {
    if (state != GameState.playing || currentPiece == null) return;

    final target = currentPiece!.moveBy(0, 1);
    if (_isValidPosition(target)) {
      currentPiece = target;
      notifyListeners();
    } else {
      if (!_isLocking) {
        _startLockTimer();
      }
    }
  }

  void _triggerHaptic(HapticFeedbackType type) {
    if (!hapticsEnabled) return;
    try {
      switch (type) {
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

enum HapticFeedbackType {
  selection,
  light,
  medium,
  heavy,
}
