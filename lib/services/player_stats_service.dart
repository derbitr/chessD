import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MatchRecord {
  final String opponent;
  final bool isWin;
  final bool isDraw;
  final String precision;
  final List<String> movesUci;
  final String playerColor;
  final String timestamp;

  MatchRecord({
    required this.opponent,
    required this.isWin,
    required this.isDraw,
    required this.precision,
    required this.movesUci,
    required this.playerColor,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'opponent': opponent,
        'is_win': isWin,
        'is_draw': isDraw,
        'precision': precision,
        'moves_uci': movesUci,
        'player_color': playerColor,
        'timestamp': timestamp,
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        opponent: json['opponent'] as String? ?? 'Oponente',
        isWin: json['is_win'] as bool? ?? false,
        isDraw: json['is_draw'] as bool? ?? false,
        precision: json['precision'] as String? ?? '--',
        movesUci: (json['moves_uci'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        playerColor: json['player_color'] as String? ?? 'white',
        timestamp: json['timestamp'] as String? ?? '',
      );
}

/// Serviço reativo para estatísticas reais do usuário (sem dados fictícios iniciais).
class PlayerStatsService extends ChangeNotifier {
  PlayerStatsService._();
  static final PlayerStatsService instance = PlayerStatsService._();

  int _puzzleRating = 1200;
  int _puzzlesSolved = 0;
  int _puzzleStreak = 0;
  int _puzzleTrailNode = 1; // Nó atual na Trilha de Problemas (1..40)

  int _bulletRating = 1200;
  int _blitzRating = 1200;
  int _rapidRating = 1200;
  int _dailyRating = 1200;

  final List<MatchRecord> _matchHistory = [];
  final Map<String, int> _lessonStars = {}; // lições concluídas pelo usuário

  int get puzzleRating => _puzzleRating;
  int get puzzlesSolved => _puzzlesSolved;
  int get puzzleStreak => _puzzleStreak;
  int get puzzleTrailNode => _puzzleTrailNode;

  int get bulletRating => _bulletRating;
  int get blitzRating => _blitzRating;
  int get rapidRating => _rapidRating;
  int get dailyRating => _dailyRating;

  List<MatchRecord> get matchHistory => List.unmodifiable(_matchHistory);
  Map<String, int> get lessonStars => Map.unmodifiable(_lessonStars);

  File? _resolveStorageFile() {
    try {
      String baseDir;
      if (Platform.isAndroid) {
        baseDir = '/data/data/com.chessd.app/files';
      } else if (Platform.isWindows) {
        baseDir = '${Platform.environment['APPDATA'] ?? Directory.systemTemp.path}\\chessD';
      } else {
        baseDir = '${Directory.systemTemp.path}/chessD';
      }
      final dir = Directory(baseDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File('$baseDir${Platform.pathSeparator}player_stats.json');
    } catch (_) {
      return null;
    }
  }

  void loadSync() {
    try {
      final file = _resolveStorageFile();
      if (file == null || !file.existsSync()) return;
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return;
      final data = jsonDecode(content) as Map<String, dynamic>;

      _puzzleRating = (data['puzzle_rating'] as num?)?.toInt() ?? 1200;
      _puzzlesSolved = (data['puzzles_solved'] as num?)?.toInt() ?? 0;
      _puzzleStreak = (data['puzzle_streak'] as num?)?.toInt() ?? 0;
      _puzzleTrailNode = (data['puzzle_trail_node'] as num?)?.toInt() ?? 1;
      _bulletRating = (data['bullet_rating'] as num?)?.toInt() ?? 1200;
      _blitzRating = (data['blitz_rating'] as num?)?.toInt() ?? 1200;
      _rapidRating = (data['rapid_rating'] as num?)?.toInt() ?? 1200;
      _dailyRating = (data['daily_rating'] as num?)?.toInt() ?? 1200;

      final historyList = data['match_history'] as List<dynamic>? ?? [];
      _matchHistory
        ..clear()
        ..addAll(historyList.map((e) => MatchRecord.fromJson(Map<String, dynamic>.from(e as Map))));

      final starsMap = data['lesson_stars'] as Map<String, dynamic>? ?? {};
      _lessonStars
        ..clear()
        ..addAll(starsMap.map((k, v) => MapEntry(k, (v as num).toInt())));

      notifyListeners();
    } catch (_) {}
  }

  void _saveSync() {
    try {
      final file = _resolveStorageFile();
      if (file == null) return;
      final payload = jsonEncode({
        'puzzle_rating': _puzzleRating,
        'puzzles_solved': _puzzlesSolved,
        'puzzle_streak': _puzzleStreak,
        'puzzle_trail_node': _puzzleTrailNode,
        'bullet_rating': _bulletRating,
        'blitz_rating': _blitzRating,
        'rapid_rating': _rapidRating,
        'daily_rating': _dailyRating,
        'match_history': _matchHistory.map((m) => m.toJson()).toList(),
        'lesson_stars': _lessonStars,
      });
      file.writeAsStringSync(payload);
    } catch (_) {}
  }

  void recordPuzzleResult({
    required bool solved,
    required int newRating,
    required int newStreak,
    int? targetTrailNode,
  }) {
    _puzzleRating = newRating;
    _puzzleStreak = newStreak;
    if (solved) {
      _puzzlesSolved += 1;
      if (targetTrailNode != null && targetTrailNode >= _puzzleTrailNode) {
        _puzzleTrailNode = (targetTrailNode + 1).clamp(1, 40);
      } else if (targetTrailNode == null) {
        _puzzleTrailNode = (_puzzleTrailNode + 1).clamp(1, 40);
      }
    }
    notifyListeners();
    _saveSync();
  }

  void recordMatch({
    required String opponent,
    required bool isWin,
    required bool isDraw,
    required String precision,
    required List<String> movesUci,
    String playerColor = 'white',
  }) {
    _matchHistory.insert(
      0,
      MatchRecord(
        opponent: opponent,
        isWin: isWin,
        isDraw: isDraw,
        precision: precision,
        movesUci: List<String>.from(movesUci),
        playerColor: playerColor,
        timestamp: DateTime.now().toIso8601String(),
      ),
    );
    if (_matchHistory.length > 50) {
      _matchHistory.removeLast();
    }
    notifyListeners();
    _saveSync();
  }

  void recordLessonCompletion(String stepId, int stars) {
    final existing = _lessonStars[stepId] ?? 0;
    if (stars > existing) {
      _lessonStars[stepId] = stars;
    }
    notifyListeners();
    _saveSync();
  }

  void resetAllForTest() {
    _puzzleRating = 1200;
    _puzzlesSolved = 0;
    _puzzleStreak = 0;
    _puzzleTrailNode = 1;
    _matchHistory.clear();
    _lessonStars.clear();
    notifyListeners();
  }
}
