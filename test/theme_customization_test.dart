import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberano_chess/ui/core/chess_theme.dart';
import 'package:soberano_chess/ui/features/settings/theme_customization_screen.dart';

void main() {
  group('Módulo de Customização Visual & Paletas (chessD)', () {
    setUp(() {
      ThemeController.instance.resetDefaults();
    });

    test('ThemeController inicializa com valores padrão canônicos', () {
      final ctrl = ThemeController.instance;

      expect(ctrl.isDark, isTrue);
      expect(ctrl.themeMode, equals(AppThemeMode.dark));
      expect(ctrl.boardTheme, equals(BoardVisualTheme.tournamentGreen));
      expect(ctrl.pieceTheme, equals(PieceVisualTheme.classicStaunton));
      expect(ctrl.accentTheme, equals(AccentVisualTheme.cyan));
      expect(ctrl.accentColor, equals(const Color(0xFF00E5FF)));
    });

    test('ThemeController alterna entre Modo Claro e Modo Noite', () {
      final ctrl = ThemeController.instance;

      ctrl.setThemeMode(AppThemeMode.light);
      expect(ctrl.isDark, isFalse);
      expect(ctrl.themeMode, equals(AppThemeMode.light));
      expect(ctrl.scaffoldBackground, equals(const Color(0xFFF8FAFC)));
      expect(ctrl.toThemeData().brightness, equals(Brightness.light));

      ctrl.setThemeMode(AppThemeMode.dark);
      expect(ctrl.isDark, isTrue);
      expect(ctrl.scaffoldBackground, equals(const Color(0xFF0B0F17)));
      expect(ctrl.toThemeData().brightness, equals(Brightness.dark));
    });

    test('ThemeController atualiza as 8 paletas de tabuleiro', () {
      final ctrl = ThemeController.instance;

      for (final board in BoardVisualTheme.values) {
        ctrl.setBoardTheme(board);
        expect(ctrl.boardTheme, equals(board));
        expect(ctrl.lightSquareColor, equals(board.lightColor));
        expect(ctrl.darkSquareColor, equals(board.darkColor));
      }
    });

    test('ThemeController atualiza as 5 paletas de peças', () {
      final ctrl = ThemeController.instance;

      for (final piece in PieceVisualTheme.values) {
        ctrl.setPieceTheme(piece);
        expect(ctrl.pieceTheme, equals(piece));
        expect(ctrl.whitePieceColor, equals(piece.whiteColor));
        expect(ctrl.blackPieceColor, equals(piece.blackColor));
      }
    });

    test('ThemeController atualiza os 6 acentos de interface e restaura padrões', () {
      final ctrl = ThemeController.instance;

      ctrl.setAccentTheme(AccentVisualTheme.amber);
      expect(ctrl.accentTheme, equals(AccentVisualTheme.amber));
      expect(ctrl.accentColor, equals(const Color(0xFFFFB300)));

      ctrl.resetDefaults();
      expect(ctrl.boardTheme, equals(BoardVisualTheme.tournamentGreen));
      expect(ctrl.pieceTheme, equals(PieceVisualTheme.classicStaunton));
      expect(ctrl.accentTheme, equals(AccentVisualTheme.cyan));
      expect(ctrl.themeMode, equals(AppThemeMode.dark));
    });

    testWidgets('ThemeCustomizationScreen renderiza preview, seletores de modo, tabuleiro, peças e acentos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeController.instance.toThemeData(),
          home: const ThemeCustomizationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica elementos de tela
      expect(find.text('Personalização Visual'), findsOneWidget);
      expect(find.text('Pré-Visualização em Tempo Real'), findsOneWidget);
      expect(find.text('Modo Noite Padrão'), findsOneWidget);
      expect(find.text('Modo Claro Padrão'), findsOneWidget);

      // Verifica nomes das paletas
      expect(find.text('Verde Torneio FIDE'), findsWidgets);
      expect(find.text('Nogueira & Carvalho Nobre'), findsOneWidget);
      expect(find.text('Oceano Meia-Noite'), findsOneWidget);
      expect(find.text('Ametista Real'), findsOneWidget);
      expect(find.text('Coral & Terracota'), findsOneWidget);
      expect(find.text('Vidro Ônix & Grafite'), findsOneWidget);
      expect(find.text('Menta Pastel'), findsOneWidget);
      expect(find.text('Monocromático Estrito'), findsOneWidget);

      // Toca em Modo Claro
      await tester.tap(find.text('Modo Claro Padrão'));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.isDark, isFalse);

      // Toca em Oceano Meia-Noite
      await tester.tap(find.text('Oceano Meia-Noite'));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.boardTheme, equals(BoardVisualTheme.midnightOcean));

      // Toca em Restaurar
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.isDark, isTrue);
      expect(ThemeController.instance.boardTheme, equals(BoardVisualTheme.tournamentGreen));
    });
  });
}
