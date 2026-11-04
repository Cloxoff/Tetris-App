import 'package:flutter/material.dart';
import '../game/tetris_engine.dart';

class ScoreHeader extends StatelessWidget {
  final TetrisEngine engine;
  final VoidCallback onRestart;

  const ScoreHeader({
    super.key,
    required this.engine,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Title & Action buttons
          Row(
            children: [
              // Logo
              const Text(
                'TETRIS',
                style: TextStyle(
                  color: Color(0xFF58A6FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              // Haptic Toggle Button
              IconButton(
                icon: Icon(
                  engine.hapticsEnabled ? Icons.vibration : Icons.smartphone,
                  size: 20,
                  color: engine.hapticsEnabled ? const Color(0xFF7EE787) : const Color(0xFF8B949E),
                ),
                tooltip: 'Вибрация',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: engine.toggleHaptics,
              ),
              // Restart Button
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFFFFA657)),
                tooltip: 'Заново',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: onRestart,
              ),
              // Pause / Resume Button
              IconButton(
                icon: Icon(
                  engine.state == GameState.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 24,
                  color: const Color(0xFF58A6FF),
                ),
                tooltip: 'Пауза',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: engine.togglePause,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Stats Row: Score, High Score, Level, Lines
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('СЧЁТ', engine.score.toString(), const Color(0xFF388BFD)),
              _buildStatItem('РЕКОРД', engine.highScore.toString(), const Color(0xFFE3B341)),
              _buildStatItem('УРОВЕНЬ', engine.level.toString(), const Color(0xFFBC8CFF)),
              _buildStatItem('ЛИНИИ', engine.lines.toString(), const Color(0xFF39D353)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
