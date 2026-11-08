import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/main.dart';

void main() {
  testWidgets('SoberanoChessApp inicializa e renderiza tela principal com todos os modos', (WidgetTester tester) async {
    // Configura resolução de tela mobile ampla para testes de integração de hub
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SoberanoChessApp());
    await tester.pumpAndSettle();

    expect(find.text('CHESS DEMOCRÁTICO'), findsOneWidget);
    expect(find.text('Trilha de Maestria (Estilo Duolingo)'), findsOneWidget);
    expect(find.text('Quebra-Cabeças Infinitos'), findsOneWidget);
    expect(find.text('Escada de Problemas (Rush 3 Vidas)'), findsOneWidget);
    expect(find.text('Revisão de Partida & Coach IA'), findsOneWidget);
    expect(find.text('Partida contra Bots'), findsOneWidget);
    expect(find.text('Pass & Play (2 Jogadores)'), findsOneWidget);
    expect(find.text('Treinador de Repertório (SM-2)'), findsOneWidget);
    expect(find.text('Explorador de Aberturas (ECO)'), findsOneWidget);
    expect(find.text('Treino de Erros Próprios'), findsOneWidget);
    expect(find.text('Estúdio de Criação de Bots'), findsOneWidget);
    expect(find.text('Torneios Locais (Sistema Suíço)'), findsOneWidget);
    expect(find.text('Perícia Forense Anti-Cheat'), findsOneWidget);
    expect(find.text('Acervo Offline & Wi-Fi Cast'), findsOneWidget);
  });
}
