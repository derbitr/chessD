import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';

void main() {
  late ChessRustFfi ffi;

  setUpAll(() {
    ffi = ChessRustFfi();
  });

  test('ChessRustFfi inicializa nova partida e lista 20 lances legais', () {
    final game = ffi.newGame();
    try {
      final fen = ffi.getCurrentFen(game);
      expect(fen, contains('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -'));

      final status = ffi.getStatus(game);
      expect(status['turn'], 'white');
      expect(status['is_check'], false);
      expect(status['is_game_over'], false);
      final legalMoves = status['legal_moves'] as List;
      expect(legalMoves.length, 20);
    } finally {
      ffi.freeGame(game);
    }
  });

  test('ChessRustFfi executa lance UCI e detecta cheque', () {
    // 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7#
    final game = ffi.newGame();
    try {
      final m1 = ffi.playUci(game, 'e2e4');
      expect(m1['uci'], 'e2e4');
      expect(m1['san'], 'e4');

      ffi.playUci(game, 'e7e5');
      ffi.playUci(game, 'd1h5');
      ffi.playUci(game, 'b8c6');
      ffi.playUci(game, 'f1c4');
      ffi.playUci(game, 'g8f6');

      final mateMove = ffi.playUci(game, 'h5f7');
      expect(mateMove['san'], contains('Qxf7'));
      expect(mateMove['is_check'], true);

      final status = ffi.getStatus(game);
      expect(status['is_game_over'], true);
      expect(status['outcome'], '1-0');
      expect(status['termination_reason'], 'checkmate');
    } finally {
      ffi.freeGame(game);
    }
  });

  test('ChessRustFfi avalia posição e bot escolhe lance legal', () {
    final game = ffi.newGame();
    try {
      final eval = ffi.evaluate(game, depth: 2);
      expect(eval['depth_reached'], 2);
      expect(eval['nodes_evaluated'], greaterThan(0));

      final botMove = ffi.getBotMove(game, elo: 1200, personality: 1);
      expect(botMove, isNotNull);
      expect(botMove!['uci'], isNotEmpty);
      expect(botMove['from'], isNotEmpty);
      expect(botMove['to'], isNotEmpty);
    } finally {
      ffi.freeGame(game);
    }
  });
}
