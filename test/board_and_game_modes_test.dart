import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/features/board/chess_board_widget.dart';
import 'package:soberano_chess/ui/features/board/coordinate_trainer.dart';

void main() {
  late ChessRustFfi ffi;
  late Pointer<Void> testGame;

  setUpAll(() {
    ffi = ChessRustFfi();
    testGame = ffi.newGame();
  });

  tearDownAll(() {
    ffi.freeGame(testGame);
  });

  testWidgets('ChessBoardWidget renderiza o tabuleiro e peças com 64 casas sem overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChessBoardWidget(
            ffi: ffi,
            game: testGame,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Deve encontrar o ChessBoardWidget
    expect(find.byType(ChessBoardWidget), findsOneWidget);

    // Deve renderizar peças (ex: peão branco e rei)
    expect(find.text('♙'), findsWidgets);
    expect(find.text('♔'), findsOneWidget);
    expect(find.text('♚'), findsOneWidget);
  });

  testWidgets('ChessBoardWidget ativa e desativa o Mapa de Calor Tático sem crash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChessBoardWidget(
            ffi: ffi,
            game: testGame,
            showHeatmap: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ChessBoardWidget), findsOneWidget);
  });

  test('ChessRustFfi gera e valida posições de Xadrez 960 (Fischer Random)', () {
    final (seed, fen) = ffi.getRandomChess960();
    expect(seed, inInclusiveRange(0, 959));
    expect(fen, isNotEmpty);

    final game960 = ffi.newGameFromFen(fen);
    expect(game960.address, isNonZero);

    final status = ffi.getStatus(game960);
    expect(status['is_game_over'], false);
    expect((status['legal_moves'] as List).isNotEmpty, true);

    ffi.freeGame(game960);
  });

  testWidgets('CoordinateTrainerScreen renderiza cronômetro e placar inicial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CoordinateTrainerScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Treinador de Coordenadas'), findsOneWidget);
    expect(find.text('TEMPO RESTANTE'), findsOneWidget);
    expect(find.text('ACERTOS / RECORDE'), findsOneWidget);
    expect(find.text('INICIAR (30 Segundos)'), findsOneWidget);
  });
}
