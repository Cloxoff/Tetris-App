import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/tetris_engine.dart';
import '../widgets/tetris_board_painter.dart';
import '../widgets/mini_board.dart';
import '../widgets/score_header.dart';
import '../widgets/control_button.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  late final TetrisEngine engine;
  final FocusNode _focusNode = FocusNode();

  // Gesture tracking
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;
  static const double _swipeThreshold = 24.0;

  @override
  void initState() {
    super.initState();
    engine = TetrisEngine();
    engine.startGame();
  }

  @override
  void dispose() {
    engine.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      engine.moveLeft();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      engine.moveRight();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      engine.softDrop();
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyX) {
      engine.rotateClockwise();
    } else if (key == LogicalKeyboardKey.keyZ) {
      engine.rotateCounterClockwise();
    } else if (key == LogicalKeyboardKey.space) {
      engine.hardDrop();
    } else if (key == LogicalKeyboardKey.keyC || key == LogicalKeyboardKey.shiftLeft) {
      engine.hold();
    } else if (key == LogicalKeyboardKey.keyP) {
      engine.togglePause();
    } else if (key == LogicalKeyboardKey.keyR) {
      engine.startGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: engine,
            builder: (context, _) {
              return Column(
                children: [
                  // Top Score & Controls Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: ScoreHeader(
                      engine: engine,
                      onRestart: () => engine.startGame(),
                    ),
                  ),

                  // Middle Game Area: HOLD - BOARD - NEXT
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Sidebar: HOLD
                          SizedBox(
                            width: 76,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: engine.hold,
                                  child: MiniBoard(
                                    title: 'ЗАПАС',
                                    pieceType: engine.holdPiece,
                                    isDimmed: !engine.canHold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (engine.combo > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9100).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFF9100), width: 1),
                                    ),
                                    child: Text(
                                      'КОМБО x${engine.combo}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFF9100),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Center: The Tetris Board with Touch Gestures
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: engine.rotateClockwise,
                                      onPanStart: (_) {
                                        _accumulatedDx = 0;
                                        _accumulatedDy = 0;
                                      },
                                      onPanUpdate: (details) {
                                        _accumulatedDx += details.delta.dx;
                                        _accumulatedDy += details.delta.dy;

                                        if (_accumulatedDx > _swipeThreshold) {
                                          engine.moveRight();
                                          _accumulatedDx = 0;
                                        } else if (_accumulatedDx < -_swipeThreshold) {
                                          engine.moveLeft();
                                          _accumulatedDx = 0;
                                        }

                                        if (_accumulatedDy > _swipeThreshold) {
                                          engine.softDrop();
                                          _accumulatedDy = 0;
                                        }
                                      },
                                      onPanEnd: (details) {
                                        if (details.velocity.pixelsPerSecond.dy > 900) {
                                          engine.hardDrop();
                                        }
                                      },
                                      child: CustomPaint(
                                        size: Size(constraints.maxWidth, constraints.maxHeight),
                                        painter: TetrisBoardPainter(
                                          board: engine.board,
                                          currentPiece: engine.currentPiece,
                                          ghostPiece: engine.ghostPiece,
                                          clearingRows: engine.clearingRows,
                                        ),
                                      ),
                                    ),

                                    // Overlays
                                    if (engine.state == GameState.paused)
                                      _buildPausedOverlay(),
                                    if (engine.state == GameState.gameOver)
                                      _buildGameOverOverlay(),
                                    if (engine.state == GameState.ready)
                                      _buildReadyOverlay(),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Right Sidebar: NEXT piece(s)
                          SizedBox(
                            width: 76,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                MiniBoard(
                                  title: 'ДАЛЕЕ',
                                  pieceType: engine.nextPieces.isNotEmpty ? engine.nextPieces[0] : null,
                                ),
                                const SizedBox(height: 10),
                                if (engine.nextPieces.length > 1)
                                  MiniBoard(
                                    title: '+1',
                                    pieceType: engine.nextPieces[1],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottom Controls: Mobile Virtual Gamepad
                  _buildBottomControls(),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- MOBILE VIRTUAL GAMEPAD ---

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131720),
        border: Border(
          top: BorderSide(color: const Color(0xFF21262D).withValues(alpha: 0.8), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left Movement Cluster: Left, Down, Right
          Row(
            children: [
              ControlButton(
                icon: const Icon(Icons.arrow_back_rounded),
                enableRepeat: true,
                size: 58,
                onPressed: engine.moveLeft,
              ),
              const SizedBox(width: 8),
              ControlButton(
                icon: const Icon(Icons.arrow_downward_rounded),
                enableRepeat: true,
                size: 58,
                color: const Color(0xFF79C0FF),
                onPressed: engine.softDrop,
              ),
              const SizedBox(width: 8),
              ControlButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                enableRepeat: true,
                size: 58,
                onPressed: engine.moveRight,
              ),
            ],
          ),

          // Center: Hard Drop Slam
          ControlButton(
            icon: const Icon(Icons.keyboard_double_arrow_down_rounded, size: 28),
            label: 'СБРОС',
            size: 60,
            color: const Color(0xFFFF7B72),
            backgroundColor: const Color(0xFF33161B),
            onPressed: engine.hardDrop,
          ),

          // Right Cluster: Rotate & Hold
          Row(
            children: [
              ControlButton(
                icon: const Icon(Icons.rotate_left_rounded),
                size: 56,
                color: const Color(0xFFD2A8FF),
                onPressed: engine.rotateCounterClockwise,
              ),
              const SizedBox(width: 8),
              ControlButton(
                icon: const Icon(Icons.rotate_right_rounded, size: 30),
                size: 64,
                color: const Color(0xFF56D364),
                backgroundColor: const Color(0xFF153322),
                onPressed: engine.rotateClockwise,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- OVERLAYS ---

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF388BFD), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ПАУЗА',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ПРОДОЛЖИТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: engine.resumeGame,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFA657)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('НАЧАТЬ ЗАНОВО'),
                onPressed: engine.startGame,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final isNewRecord = engine.score > 0 && engine.score >= engine.highScore;

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNewRecord ? const Color(0xFFE3B341) : const Color(0xFFF85149),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isNewRecord ? const Color(0xFFE3B341) : const Color(0xFFF85149)).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ИГРА ОКОНЧЕНА',
                style: TextStyle(
                  color: isNewRecord ? const Color(0xFFE3B341) : const Color(0xFFF85149),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              if (isNewRecord) ...[
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFFE3B341), size: 20),
                    SizedBox(width: 6),
                    Text(
                      'НОВЫЙ РЕКОРД!',
                      style: TextStyle(
                        color: Color(0xFFE3B341),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  children: [
                    _buildModalStat('Счёт:', engine.score.toString(), const Color(0xFF58A6FF)),
                    const SizedBox(height: 6),
                    _buildModalStat('Рекорд:', engine.highScore.toString(), const Color(0xFFE3B341)),
                    const SizedBox(height: 6),
                    _buildModalStat('Линий собрано:', engine.lines.toString(), const Color(0xFF39D353)),
                    const SizedBox(height: 6),
                    _buildModalStat('Уровень:', engine.level.toString(), const Color(0xFFBC8CFF)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: const Text(
                  'ИГРАТЬ СНОВА',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                onPressed: engine.startGame,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('СТАРТ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          onPressed: engine.startGame,
        ),
      ),
    );
  }

  Widget _buildModalStat(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
