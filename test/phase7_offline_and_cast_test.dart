import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/services/wifi_cast_server.dart';
import 'package:chess_d/ui/features/settings/offline_packs_screen.dart';

void main() {
  group('Fase 7 - Servidor Wi-Fi Cast (Smart TV & PC)', () {
    test('WifiCastServer inicia, atualiza estado da partida e encerra sem erros', () async {
      final server = WifiCastServer();
      expect(server.isRunning, isFalse);

      final started = await server.start(port: 0); // Porta efêmera para teste
      expect(started, isTrue);
      expect(server.isRunning, isTrue);
      expect(server.port, greaterThan(0));

      server.updateState(
        fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        moves: ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
      );

      await server.stop();
      expect(server.isRunning, isFalse);
    });
  });

  group('Fase 7 - Gerenciador de Acervo Offline (Zstandard 4M+)', () {
    testWidgets('OfflinePacksScreen renderiza pacotes Zstd e controle do Wi-Fi Cast', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final castServer = WifiCastServer();

      await tester.pumpWidget(
        MaterialApp(
          home: OfflinePacksScreen(castServer: castServer),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acervo Offline & Conectividade'), findsOneWidget);
      expect(find.text('Espelhamento Wi-Fi Cast'), findsOneWidget);
      expect(find.text('Pacote Base Tático Essencial'), findsOneWidget);
      expect(find.text('ATIVO'), findsOneWidget);

      await castServer.stop();
    });
  });
}
