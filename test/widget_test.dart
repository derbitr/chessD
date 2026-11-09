import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/main.dart';

void main() {
  testWidgets('ChessDApp inicializa e renderiza tela principal com todos os modos', (WidgetTester tester) async {
    // Configura resolução de tela mobile ampla para testes de integração de hub
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const ChessDApp());
    await tester.pumpAndSettle();

    // Valida Header e Identidade Visual
    expect(find.text('chessD'), findsOneWidget);

    // Valida BottomNavigationBar com 5 abas estilo Chess.com
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Problemas'), findsWidgets);
    expect(find.text('Aprender'), findsOneWidget);
    expect(find.text('Assistir'), findsOneWidget);
    expect(find.text('Mais'), findsOneWidget);

    // Valida CTA Verde Canônico "Jogar" e Cards Iniciais
    expect(find.text('Jogar'), findsWidgets);
    expect(find.text('Problema Diário'), findsOneWidget);
    expect(find.text('Jogar com Bots'), findsWidgets);
    expect(find.text('O Ornitólogo'), findsOneWidget);
    expect(find.text('O Trilheiro'), findsWidgets);

    // Valida navegação entre as abas
    await tester.tap(find.text('Problemas').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprender'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assistir'));
    await tester.pumpAndSettle();
    expect(find.text('Perícia Forense Anti-Cheat'), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();

    expect(find.text('Torneios (Sistema Suíço FIDE)'), findsOneWidget);
    expect(find.text('Estúdio de Criação de Bots'), findsOneWidget);
  });
}
