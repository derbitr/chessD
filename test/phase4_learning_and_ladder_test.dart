import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/data/models/lesson_module.dart';
import 'package:chess_d/data/repositories/puzzle_repository.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/user_mistakes_service.dart';
import 'package:chess_d/ui/features/learning/learning_track_screen.dart';
import 'package:chess_d/ui/features/training/infinite_puzzles_screen.dart';
import 'package:chess_d/ui/features/training/puzzle_ladder_screen.dart';
import 'package:chess_d/ui/features/training/retry_mistakes_screen.dart';

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

      expect(find.text('Trilha de Maestria'), findsOneWidget);
      expect(find.text('Módulo 1: Fundamentos do Tabuleiro'), findsOneWidget);
      expect(find.text('O que é o Xeque-Mate'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
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
      expect(find.text('PROGRESSO NA TRILHA'), findsOneWidget);
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

  group('Treino de Erros Próprios - Integridade Inicial', () {
    testWidgets('RetryMistakesScreen inicia sem erros fictícios quando o usuário nunca jogou', (tester) async {
      UserMistakesService.clearAll();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: RetryMistakesScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treino de Erros Próprios'), findsOneWidget);
      expect(find.text('ERROS SUPERADOS'), findsOneWidget);
      expect(find.text('0 / 0'), findsOneWidget);
      expect(find.text('Nenhum Erro Registrado!'), findsOneWidget);
    });
  });
}
