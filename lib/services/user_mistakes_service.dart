import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Serviço de Gerenciamento de Erros Próprios (Retry Mistakes)
/// Armazena gafes, erros táticos e imprecisões cometidas genuinamente pelo usuário
/// durante partidas contra bots ou quebra-cabeças.
class UserMistakesService {
  UserMistakesService._();

  static final List<Map<String, dynamic>> _mistakes = [];
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static List<Map<String, dynamic>> get mistakes => List.unmodifiable(_mistakes);

  static int get totalCount => _mistakes.length;
  static int get solvedCount => _mistakes.where((m) => m['is_solved'] == true).length;

  static File? _resolveStorageFile() {
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
      return File('$baseDir${Platform.pathSeparator}user_mistakes.json');
    } catch (_) {
      return null;
    }
  }

  static void loadSync() {
    try {
      final file = _resolveStorageFile();
      if (file == null || !file.existsSync()) return;
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return;
      final list = jsonDecode(content) as List<dynamic>;
      _mistakes
        ..clear()
        ..addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      changeNotifier.value++;
    } catch (_) {}
  }

  static void _saveSync() {
    try {
      final file = _resolveStorageFile();
      if (file == null) return;
      file.writeAsStringSync(jsonEncode(_mistakes));
    } catch (_) {}
  }

  /// Registra uma nova gafe/erro real cometido pelo usuário
  static void recordMistake({
    required String title,
    required String fen,
    required String blunderPlayedUci,
    required String bestMoveUci,
    required String explanation,
  }) {
    // Evita duplicatas da mesma posição
    if (_mistakes.any((m) => m['fen'] == fen)) return;

    _mistakes.insert(0, {
      'id': 'mistake_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'fen': fen,
      'blunder_played_uci': blunderPlayedUci,
      'best_move_uci': bestMoveUci,
      'explanation': explanation,
      'is_solved': false,
      'timestamp': DateTime.now().toIso8601String(),
    });

    changeNotifier.value++;
    _saveSync();
  }

  /// Marca um erro como resolvido/superado
  static void markSolved(String id) {
    final idx = _mistakes.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      _mistakes[idx]['is_solved'] = true;
      changeNotifier.value++;
      _saveSync();
    }
  }

  /// Carrega exercícios de treino de exemplo (apenas mediante solicitação explícita)
  static void loadSampleDrills() {
    if (_mistakes.isNotEmpty) return;

    _mistakes.addAll([
      {
        'id': 'sample_1',
        'title': 'Gafe: Peça Pendurada na Abertura',
        'fen': 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 2 3',
        'blunder_played_uci': 'd2d3',
        'best_move_uci': 'd1h5',
        'explanation': 'O golpe ativo era Dh5 com forte ameaça de mate em f7.',
        'is_solved': false,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'id': 'sample_2',
        'title': 'Erro: Mate de Corredor Desperdiçado',
        'fen': '6k1/5ppp/8/8/8/8/1R3PPP/2R3K1 w - - 0 1',
        'blunder_played_uci': 'b2b3',
        'best_move_uci': 'c1c8',
        'explanation': 'A oitava fila estava vulnerável. Tc8# aplicava xeque-mate imediato.',
        'is_solved': false,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'id': 'sample_3',
        'title': 'Imprecisão: Garfo de Cavalo Perdido',
        'fen': 'r1b1k2r/pppp1ppp/8/2b1n3/3PP3/2N5/PPP2PPP/R1B1KB1R w KQkq - 0 1',
        'blunder_played_uci': 'f1e2',
        'best_move_uci': 'd4e5',
        'explanation': 'Capturar o cavalo em e5 com dxe5 ganha uma peça inteira.',
        'is_solved': false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ]);

    changeNotifier.value++;
    _saveSync();
  }

  static void clearAll() {
    _mistakes.clear();
    changeNotifier.value++;
    _saveSync();
  }
}
