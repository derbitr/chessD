import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/services/p2p_multiplayer_service.dart';
import 'package:soberano_chess/ui/features/multiplayer/online_multiplayer_screen.dart';
import 'package:soberano_chess/ui/features/settings/help_support_screen.dart';

void main() {
  group('Módulo Multiplayer Online P2P & Ajuda (chessD)', () {
    test('P2PMultiplayerService gera código de sala de 6 caracteres válido', () {
      final code = P2PMultiplayerService.generateRoomCode();
      expect(code.length, equals(6));
      expect(code, matches(r'^[A-Z0-9]{6}$'));
    });

    test('P2PMultiplayerService cria sala e inicializa relógios e conexões', () async {
      final service = P2PMultiplayerService.instance;
      final roomCode = await service.createRoom(
        preferredColor: PlayerColor.white,
        timeMinutes: 3,
        incrementSeconds: 2,
      );

      expect(roomCode.length, equals(6));
      expect(service.roomCode, equals(roomCode));
      expect(service.myRemainingTimeMs, equals(180000));
      expect(service.timeIncrementMs, equals(2000));
      expect(service.assignedColor, equals(PlayerColor.white));

      service.disconnect();
      expect(service.state, equals(MultiplayerConnectionState.disconnected));
      expect(service.roomCode, isNull);
    });

    testWidgets('OnlineMultiplayerScreen renderiza lobby com controles de tempo e botões', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineMultiplayerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multiplayer Online (Custo Zero)'), findsOneWidget);
      expect(find.text('Rede P2P & Borda Serverless'), findsOneWidget);
      expect(find.text('Criar Nova Partida'), findsOneWidget);
      expect(find.text('Criar Sala & Gerar Código'), findsOneWidget);
      expect(find.text('Entrar em Sala de Amigo'), findsOneWidget);
      expect(find.text('1 min (Bullet)'), findsOneWidget);
      expect(find.text('3 + 2s (Blitz)'), findsOneWidget);
      expect(find.text('5 + 3s (Rápida)'), findsOneWidget);
    });

    testWidgets('HelpSupportScreen renderiza categorias, regras FIDE e FAQ', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Central de Ajuda & Guia chessD'), findsOneWidget);
      expect(find.text('Guia Completo do chessD'), findsOneWidget);
      expect(find.text('Multiplayer Online Custo Zero'), findsOneWidget);
      expect(find.text('Regras Oficiais FIDE'), findsOneWidget);
      expect(find.text('Recursos Avançados chessD'), findsOneWidget);
      expect(find.text('Perguntas Frequentes (FAQ)'), findsOneWidget);

      // Testa expansão de um card de ajuda
      await tester.tap(find.text('Como funciona o Multiplayer Custo Zero?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('WebRTC P2P Direto'), findsOneWidget);
    });
  });
}
