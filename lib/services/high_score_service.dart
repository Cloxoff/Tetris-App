import 'dart:io';

class HighScoreService {
  static int _cachedHighScore = 0;
  static bool _initialized = false;

  static Future<int> getHighScore() async {
    if (_initialized) return _cachedHighScore;
    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        _cachedHighScore = int.tryParse(content.trim()) ?? 0;
      }
    } catch (_) {
      // Graceful fallback to memory
    }
    _initialized = true;
    return _cachedHighScore;
  }

  static Future<void> saveHighScore(int score) async {
    if (score <= _cachedHighScore) return;
    _cachedHighScore = score;
    try {
      final file = await _getStorageFile();
      if (file != null) {
        await file.writeAsString(score.toString());
      }
    } catch (_) {
      // Ignore if sandbox prevents direct file write without path_provider
    }
  }

  static Future<File?> _getStorageFile() async {
    try {
      // For Android internal storage
      final androidPath = Directory('/data/user/0/com.example.tetris_mobile/files');
      if (await androidPath.exists()) {
        return File('${androidPath.path}/highscore.txt');
      }
      final fallbackDir = Directory.systemTemp;
      return File('${fallbackDir.path}/tetris_highscore.txt');
    } catch (_) {
      return null;
    }
  }
}
