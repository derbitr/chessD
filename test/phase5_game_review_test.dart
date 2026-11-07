import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/features/analysis/game_review_screen.dart';
import 'package:soberano_chess/ui/features/analysis/share_card_generator.dart';

void main() {
  late ChessRustFfi ffi;

  setUpAll(() {
    ffi = ChessRustFfi();
  });

  group('Fase 5 - Algoritmo CAPS2 & Classificação de Lances no Rust Core', () {
    test('Classificação de lance Best (★) produz precisão próxima de 100%', () {
      final analysis = ffi.classifyMove(
        isWhite: true,
        playedUci: 'e2e4',
        bestUci: 'e2e4',
        evalBefore: 20,
        evalAfter: 25,
      );

      expect(analysis['category'], equals('Best'));
      expect(analysis['move_accuracy'], greaterThanOrEqualTo(99.0));
      expect(analysis['pedagogical_explanation'], contains('Melhor lance'));
      expect(analysis['is_panic_move'], isFalse);
    });

    test('Classificação de Gafe (??) sob apuro de tempo (<800ms) aciona flag de pânico/tilt', () {
      final analysis = ffi.classifyMove(
        isWhite: true,
        playedUci: 'f2f3',
        bestUci: 'e2e4',
        evalBefore: 20,
        evalAfter: -450, // Perda severa de vantagem
        timeSpentMs: 400, // < 800ms
      );

      expect(analysis['category'], equals('Blunder'));
      expect(analysis['move_accuracy'], lessThan(20.0));
      expect(analysis['is_panic_move'], isTrue);
      expect(analysis['pedagogical_explanation'], contains('Gafe'));
      expect(analysis['pedagogical_explanation'], contains('desespero sob pressão de tempo'));
    });

    test('Classificação de lance Brilhante (!!) para sacrifício com vantagem tática', () {
      final analysis = ffi.classifyMove(
        isWhite: true,
        playedUci: 'b5d7',
        bestUci: 'b5d7',
        evalBefore: 300,
        evalAfter: 500,
        isSacrifice: true,
      );

      expect(analysis['category'], equals('Brilliant'));
      expect(analysis['pedagogical_explanation'], contains('Brilhante'));
      expect(analysis['pedagogical_explanation'], contains('sacrifício tático'));
    });
  });

  group('Fase 5 - Tela de Revisão de Partida & Coach IA (Widget)', () {
    testWidgets('GameReviewScreen calcula precisão de ambos os lados e exibe explicação do Coach', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Partida rápida de teste (Mate do Pastor: 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7#)
      final moves = ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'];

      await tester.pumpWidget(
        MaterialApp(
          home: GameReviewScreen(
            ffi: ffi,
            movesPlayedUci: moves,
            playerColor: 'white',
          ),
        ),
      );

      // Aguarda cálculo do CAPS2 e renderização
      await tester.pumpAndSettle();

      expect(find.text('Revisão da Partida & Coach IA'), findsOneWidget);
      expect(find.text('BRANCAS (VOCÊ)'), findsOneWidget);
      expect(find.text('PRETAS (BOT)'), findsOneWidget);
      expect(find.text('CURVA DE VANTAGEM POR LANCE'), findsOneWidget);
      expect(find.textContaining('Treinador IA'), findsOneWidget);
    });
  });

  group('Fase 5 - Cartão Viral de Compartilhamento (ShareCardScreen)', () {
    testWidgets('ShareCardScreen renderiza duel badges e permite exportar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ShareCardScreen(
            whiteAccuracy: 88.5,
            blackAccuracy: 64.2,
            brilliantsCount: 2,
            blundersCount: 1,
            playerName: 'Magnus',
            opponentName: 'Bot Nível 5',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SOBERANO CHESS'), findsOneWidget);
      expect(find.text('88.5%'), findsOneWidget);
      expect(find.text('64.2%'), findsOneWidget);
      expect(find.text('Lances Brilhantes (!!)'), findsOneWidget);
      expect(find.text('Gafes Cometidas (??)'), findsOneWidget);
      expect(find.text('COMPARTILHAR CARD (INSTAGRAM / WHATSAPP)'), findsOneWidget);

      // Toca em compartilhar card e verifica mensagem de sucesso
      await tester.tap(find.text('COMPARTILHAR CARD (INSTAGRAM / WHATSAPP)'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Card de Partida copiado para a galeria e compartilhado!'), findsOneWidget);
    });
  });
}
