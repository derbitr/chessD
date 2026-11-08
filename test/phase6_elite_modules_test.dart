import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/features/analysis/anti_cheat_audit_screen.dart';
import 'package:soberano_chess/ui/features/game/bot_studio_screen.dart';
import 'package:soberano_chess/ui/features/openings/opening_explorer_screen.dart';
import 'package:soberano_chess/ui/features/repertoire/repertoire_trainer_screen.dart';
import 'package:soberano_chess/ui/features/training/retry_mistakes_screen.dart';
import 'package:soberano_chess/ui/features/tournament/tournament_manager_screen.dart';

void main() {
  late ChessRustFfi ffi;

  setUpAll(() {
    ffi = ChessRustFfi();
  });

  group('Fase 6 - Algoritmo SuperMemo SM-2 & Repertório', () {
    test('FFI SM-2 calcula novo intervalo e fator de facilidade', () {
      final card = {
        'id': 'test_card',
        'opening_name': 'Abertura Italiana',
        'fen': 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
        'expected_move_uci': 'c2c3',
        'repetition': 0,
        'interval_days': 1,
        'ease_factor': 2.5,
        'next_review_epoch': 0,
      };

      // Avaliação perfeita (qualidade 5)
      final updated = ffi.reviewSrsCard(card, 5, 1700000000);
      expect(updated['repetition'], equals(1));
      expect(updated['interval_days'], equals(1));
      expect(updated['ease_factor'], greaterThanOrEqualTo(2.5));
    });

    testWidgets('RepertoireTrainerScreen renderiza tabuleiro e opções SM-2 após lance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: RepertoireTrainerScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treinador de Repertório (SM-2)'), findsOneWidget);
      expect(find.textContaining('Abertura Italiana'), findsWidgets);
    });
  });

  group('Fase 6 - Explorador de Aberturas (ECO)', () {
    test('FFI retorna catálogo canônico com linhas teóricas e estatísticas', () {
      final catalog = ffi.getOpeningsCatalog();
      expect(catalog.length, greaterThanOrEqualTo(3));

      final italian = catalog.firstWhere((op) => op['eco'] == 'C50', orElse: () => null);
      expect(italian, isNotNull);
      expect(italian['candidate_moves'], isNotEmpty);
    });

    testWidgets('OpeningExplorerScreen renderiza seletor de variantes e lances mestres', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: OpeningExplorerScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explorador de Aberturas (ECO)'), findsOneWidget);
      expect(find.text('LANCES MESTRES & ESTATÍSTICAS DE VITÓRIA'), findsOneWidget);
    });
  });

  group('Fase 6 - Sistema Suíço de Torneios (FIDE)', () {
    test('FFI gera emparceiramentos da primeira rodada sem repetição de confrontos', () {
      final players = [
        {'id': 'p1', 'name': 'Magnus', 'rating': 2850, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': [], 'color_history': [], 'had_bye': false},
        {'id': 'p2', 'name': 'Hikaru', 'rating': 2800, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': [], 'color_history': [], 'had_bye': false},
        {'id': 'p3', 'name': 'Alireza', 'rating': 2780, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': [], 'color_history': [], 'had_bye': false},
        {'id': 'p4', 'name': 'Gukesh', 'rating': 2760, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': [], 'color_history': [], 'had_bye': false},
      ];

      final res = ffi.generateSwissPairings(players);
      final pairings = res['pairings'] as List<dynamic>;
      expect(pairings.length, equals(2));
    });

    testWidgets('TournamentManagerScreen renderiza tabela de classificação e botão de emparceirar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: TournamentManagerScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Torneios (Sistema Suíço FIDE)'), findsOneWidget);
      expect(find.text('CLASSIFICAÇÃO GERAL'), findsOneWidget);
      expect(find.text('Magnus'), findsWidgets);
    });
  });

  group('Fase 6 - Perícia Forense Anti-Cheat', () {
    test('FFI detecta anomalia estatística em partida assistida por engine', () {
      final moves = List<String>.generate(20, (i) => 'm_$i');
      final top1 = List<String>.from(moves);
      final top2 = List<String>.from(moves);
      final cpls = List<int>.generate(20, (i) => 2);
      final times = List<int>.generate(20, (i) => 1000);

      final report = ffi.auditAntiCheat(
        movesPlayed: moves,
        engineTop1: top1,
        engineTop2: top2,
        centipawnLosses: cpls,
        moveTimesMs: times,
      );

      expect(report['verdict'], equals('HighlyAnomalous'));
      expect(report['cheat_probability_score'], greaterThanOrEqualTo(80.0));
      expect(report['top1_match_pct'], greaterThanOrEqualTo(95.0));
    });

    testWidgets('AntiCheatAuditScreen renderiza card de veredito forense', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AntiCheatAuditScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perícia Forense Anti-Cheat'), findsOneWidget);
      expect(find.textContaining('Probabilidade de Assistência'), findsOneWidget);
    });
  });

  group('Fase 6 - Treino de Erros Próprios & Bot Studio', () {
    testWidgets('RetryMistakesScreen renderiza gafe e tabuleiro interativo', (tester) async {
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
    });

    testWidgets('BotStudioScreen permite ajustar Elo e estilo de jogo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: BotStudioScreen(ffi: ffi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estúdio de Criação de Bots'), findsOneWidget);
      expect(find.text('FORÇA DE CÁLCULO (ELO)'), findsOneWidget);
      expect(find.text('JOGAR CONTRA ESTE BOT'), findsOneWidget);
    });
  });
}
