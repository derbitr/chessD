import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/data/models/lesson_module.dart';
import 'package:soberano_chess/data/repositories/puzzle_repository.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';

void main() {
  late ChessRustFfi ffi;
  late PuzzleRepository puzzleRepo;

  setUpAll(() {
    ffi = ChessRustFfi();
    puzzleRepo = PuzzleRepository();
  });

  test('Currículo Híbrido possui módulos válidos com FENs e soluções testadas no Rust', () {
    final modules = LessonModule.getCuratedCurriculum();
    expect(modules.length, greaterThanOrEqualTo(4));

    for (final mod in modules) {
      expect(mod.title, isNotEmpty);
      expect(mod.steps, isNotEmpty);

      for (final step in mod.steps) {
        expect(step.shortTheory, isNotEmpty);

        // Testa se o FEN de demonstração é matematicamente válido no Rust
        final demoGame = ffi.newGameFromFen(step.demonstrationFen);
        expect(demoGame.address, isNonZero);
        ffi.freeGame(demoGame);

        for (final ex in step.exercises) {
          expect(ex.solutionUciMoves, isNotEmpty);
          final exGame = ffi.newGameFromFen(ex.initialFen);
          expect(exGame.address, isNonZero);

          // Testa se o primeiro lance da solução é legal na posição inicial
          final status = ffi.getStatus(exGame);
          final legalUcis = (status['legal_moves'] as List).map((m) => m['uci'].toString()).toList();
          expect(
            legalUcis.contains(ex.solutionUciMoves.first),
            isTrue,
            reason: 'Lance ${ex.solutionUciMoves.first} deve ser legal no FEN ${ex.initialFen}',
          );

          ffi.freeGame(exGame);
        }
      }
    }
  });

  test('PuzzleRepository retorna quebra-cabeças adaptativos calibrados por rating', () async {
    final puzzleLow = await puzzleRepo.getAdaptivePuzzle(600);
    expect(puzzleLow.rating, lessThanOrEqualTo(1100));

    final puzzleHigh = await puzzleRepo.getAdaptivePuzzle(2000);
    expect(puzzleHigh.rating, greaterThanOrEqualTo(1400));
  });

  test('PuzzleRepository gera Escada de Problemas com progressão monótona de Elo', () async {
    final ladder = await puzzleRepo.getLadderSequence();
    expect(ladder.length, greaterThanOrEqualTo(5));

    for (int i = 0; i < ladder.length - 1; i++) {
      expect(
        ladder[i].rating <= ladder[i + 1].rating,
        isTrue,
        reason: 'Problema $i (${ladder[i].rating}) deve ser menor ou igual a ${i + 1} (${ladder[i + 1].rating})',
      );
    }
  });
}
