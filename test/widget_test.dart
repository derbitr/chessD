import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/main.dart';

void main() {
  testWidgets('SoberanoChessApp inicializa e renderiza tela principal com todos os modos', (WidgetTester tester) async {
    // Configura resolução de tela mobile padrão
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SoberanoChessApp());
    await tester.pumpAndSettle();

    expect(find.text('SOBERANO CHESS'), findsOneWidget);
    expect(find.text('Trilha de Maestria (Estilo Duolingo)'), findsOneWidget);
    expect(find.text('Quebra-Cabeças Infinitos'), findsOneWidget);
    expect(find.text('Escada de Problemas (Rush 3 Vidas)'), findsOneWidget);
    expect(find.text('Revisão de Partida & Coach IA'), findsOneWidget);
    expect(find.text('Partida contra Bots'), findsOneWidget);
    expect(find.text('Pass & Play (2 Jogadores)'), findsOneWidget);
  });
}
