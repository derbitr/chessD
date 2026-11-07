import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/data/models/lesson_module.dart';
import 'package:soberano_chess/data/repositories/puzzle_repository.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/features/learning/learning_track_screen.dart';
import 'package:soberano_chess/ui/features/training/infinite_puzzles_screen.dart';
import 'package:soberano_chess/ui/features/training/puzzle_ladder_screen.dart';

void main() {
  late ChessRustFfi ffi;

  setUpAll(() {
    ffi = ChessRustFfi();
  });

  group('Fase 4 - Trilha de Aprendizado & Currículo Estruturado', () {
    test('Currículo possui módulos estruturados com FENs e soluções válidas', () {
      final curriculum = LessonModule.getCuratedCurriculum();
      expect(curriculum.length, greaterThanOrEqualTo(4));

      for (final mod in curriculum) {
        expect(mod.title.isNotEmpty, isTrue);
        expect(mod.steps.isNotEmpty, isTrue);
        for (final step in mod.steps) {
          expect(step.title.isNotEmpty, isTrue);
          expect(step.shortTheory.isNotEmpty, isTrue);
        }
      }
    });

    testWidgets('LearningTrackScreen renderiza nós da trilha senoidal com status de estrelas', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: LearningTrackScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trilha de Maestria (Estilo Duolingo)'), findsOneWidget);
      expect(find.text('Módulo 1: Fundamentos'), findsOneWidget);
      expect(find.text('O que é o Xeque-Mate'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });

  group('Fase 4 - Quebra-Cabeças Infinitos & Elo Adaptativo', () {
    test('Cálculo de rating de puzzle no Rust recompensa acertos e pune erros', () {
      final winRes = ffi.updatePuzzleRating(
        playerRating: 1200,
        puzzleRating: 1250,
        isSuccess: true,
        currentStreak: 2,
      );

      expect(winRes['new_rating'], greaterThan(1200));
      expect(winRes['change'], greaterThan(0));
      expect(winRes['current_streak'], equals(3));

      final lossRes = ffi.updatePuzzleRating(
        playerRating: 1200,
        puzzleRating: 1100,
        isSuccess: false,
        currentStreak: 5,
      );

      expect(lossRes['new_rating'], lessThan(1200));
      expect(lossRes['change'], lessThan(0));
      expect(lossRes['current_streak'], equals(0)); // Reseta streak
    });

    testWidgets('InfinitePuzzlesScreen carrega puzzle adaptativo e exibe instruções', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: InfinitePuzzlesScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quebra-Cabeças Infinitos'), findsOneWidget);
      expect(find.text('SEU RATING TÁTICO'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });

  group('Fase 4 - Escada de Problemas (Puzzle Rush / 3 Vidas)', () {
    test('Repositório gera sequência monotônica crescente de dificuldade', () async {
      final repo = PuzzleRepository();
      final sequence = await repo.getLadderSequence();

      expect(sequence.length, greaterThanOrEqualTo(5));
      for (int i = 0; i < sequence.length - 1; i++) {
        expect(sequence[i].rating, lessThanOrEqualTo(sequence[i + 1].rating));
      }
    });

    testWidgets('PuzzleLadderScreen inicializa com 3 corações/vidas cheias', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: PuzzleLadderScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escada de Problemas (Puzzle Rush)'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
      expect(find.text('VIDAS RESTANTES'), findsOneWidget);
      expect(find.text('0 / 0'), findsOneWidget);
    });
  });
}
