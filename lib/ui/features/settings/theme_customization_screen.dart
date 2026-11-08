import 'package:flutter/material.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import 'package:chess_d/ui/core/app_typography.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  final ThemeController _controller = ThemeController.instance;

  // Layout estático demonstrativo para o tabuleiro de visualização
  static const Map<String, String> _previewPieces = {
    'd1': 'Q',
    'e1': 'K',
    'c1': 'B',
    'b1': 'N',
    'a2': 'P',
    'b2': 'P',
    'c2': 'P',
    'd4': 'P',
    'e4': 'P',
    'd8': 'q',
    'e8': 'k',
    'c8': 'b',
    'b8': 'n',
    'a7': 'p',
    'b7': 'p',
    'c7': 'p',
    'd5': 'p',
    'e5': 'p',
    'f3': 'N',
    'c6': 'n',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isDark = _controller.isDark;
        final bg = _controller.scaffoldBackground;
        final surface = _controller.surfaceColor;
        final border = _controller.borderColor;
        final textPri = _controller.textPrimary;
        final textSec = _controller.textSecondary;
        final accent = _controller.accentColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text('Personalização Visual', style: AppTypography.titleLarge.copyWith(color: textPri)),
            backgroundColor: surface,
            elevation: 0,
            iconTheme: IconThemeData(color: textPri),
            actions: [
              TextButton.icon(
                onPressed: () => _controller.resetDefaults(),
                icon: Icon(Icons.refresh, size: 18, color: accent),
                label: Text('Restaurar', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Tabuleiro Interativo de Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.remove_red_eye_outlined, color: accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pré-Visualização em Tempo Real',
                                style: AppTypography.titleMedium.copyWith(color: textPri),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _controller.boardTheme.name,
                              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              children: List.generate(8, (rowIdx) {
                                final rank = 8 - rowIdx;
                                return Expanded(
                                  child: Row(
                                    children: List.generate(8, (colIdx) {
                                      final file = String.fromCharCode('a'.codeUnitAt(0) + colIdx);
                                      final square = '$file$rank';
                                      final isLight = (colIdx + rank) % 2 != 0;
                                      final baseColor = isLight
                                          ? _controller.lightSquareColor
                                          : _controller.darkSquareColor;

                                      final isSelected = square == 'e4';
                                      final isLegalDot = square == 'e5' || square == 'd5';

                                      Color sqColor = baseColor;
                                      if (isSelected) {
                                        sqColor = Color.alphaBlend(accent.withOpacity(0.55), sqColor);
                                      }

                                      final piece = _previewPieces[square];
                                      final isWhite = piece != null && piece.toUpperCase() == piece;
                                      final pieceColor = isWhite
                                          ? _controller.whitePieceColor
                                          : _controller.blackPieceColor;

                                      return Expanded(
                                        child: Container(
                                          color: sqColor,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (piece != null)
                                                Text(
                                                  _getPieceSymbol(piece),
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    height: 1.0,
                                                    color: pieceColor,
                                                    shadows: [
                                                      Shadow(
                                                        color: isWhite ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.25),
                                                        blurRadius: 3,
                                                        offset: const Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (isLegalDot)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: accent.withOpacity(0.85),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Seletor de Modo de Exibição (Modo Claro vs Modo Noite)
                Text('MODO DE EXIBIÇÃO', style: AppTypography.labelSmall.copyWith(color: textSec)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeModeCard(
                        title: 'Modo Noite Padrão',
                        subtitle: 'OLED Obsidian Dark',
                        icon: Icons.nightlight_round,
                        isSelected: isDark,
                        onTap: () => _controller.setThemeMode(AppThemeMode.dark),
                        surface: surface,
                        border: border,
                        accent: accent,
                        textPri: textPri,
                        textSec: textSec,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildThemeModeCard(
                        title: 'Modo Claro Padrão',
                        subtitle: 'Clean Slate Off-White',
                        icon: Icons.wb_sunny_rounded,
                        isSelected: !isDark,
                        onTap: () => _controller.setThemeMode(AppThemeMode.light),
                        surface: surface,
                        border: border,
                        accent: accent,
                        textPri: textPri,
                        textSec: textSec,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Paletas de Cores do Tabuleiro (8 Opções)
                Text('PALETA DE CORES DO TABULEIRO', style: AppTypography.labelSmall.copyWith(color: textSec)),
                const SizedBox(height: 10),
                ...BoardVisualTheme.values.map((boardOpt) {
                  final isSelected = _controller.boardTheme == boardOpt;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _controller.setBoardTheme(boardOpt),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accent : border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black26),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Container(color: boardOpt.lightColor)),
                                    Expanded(child: Container(color: boardOpt.darkColor)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(boardOpt.name, style: TextStyle(color: textPri, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(boardOpt.description, style: TextStyle(color: textSec, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: accent, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // 4. Paleta de Cores das Peças (5 Opções)
                Text('ESTILO E CORES DAS PEÇAS', style: AppTypography.labelSmall.copyWith(color: textSec)),
                const SizedBox(height: 10),
                ...PieceVisualTheme.values.map((pieceOpt) {
                  final isSelected = _controller.pieceTheme == pieceOpt;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _controller.setPieceTheme(pieceOpt),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accent : border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2838) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '♔',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: pieceOpt.whiteColor,
                                        shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '♚',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: pieceOpt.blackColor,
                                        shadows: const [Shadow(color: Colors.white24, blurRadius: 2)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pieceOpt.name, style: TextStyle(color: textPri, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(pieceOpt.description, style: TextStyle(color: textSec, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: accent, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // 5. Cores de Acento da Interface (6 Opções)
                Text('COR DE DESTAQUE DA INTERFACE (ACENTO)', style: AppTypography.labelSmall.copyWith(color: textSec)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AccentVisualTheme.values.map((accentOpt) {
                    final isSelected = _controller.accentTheme == accentOpt;

                    return GestureDetector(
                      onTap: () => _controller.setAccentTheme(accentOpt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accentOpt.color : border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: accentOpt.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentOpt.color.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              accentOpt.name,
                              style: TextStyle(
                                color: isSelected ? accentOpt.color : textPri,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color surface,
    required Color border,
    required Color accent,
    required Color textPri,
    required Color textSec,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? accent : textSec, size: 24),
                if (isSelected)
                  Icon(Icons.check_circle, color: accent, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: textPri, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: textSec, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _getPieceSymbol(String char) {
    switch (char) {
      case 'P': return '♙';
      case 'N': return '♘';
      case 'B': return '♗';
      case 'R': return '♖';
      case 'Q': return '♕';
      case 'K': return '♔';
      case 'p': return '♟';
      case 'n': return '♞';
      case 'b': return '♝';
      case 'r': return '♜';
      case 'q': return '♛';
      case 'k': return '♚';
      default: return '';
    }
  }
}
