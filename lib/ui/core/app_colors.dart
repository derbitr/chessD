import 'package:flutter/material.dart';

/// Paleta de Cores Soberana
/// Projetada com contraste superior a 12:1 (acima do WCAG AAA 7:1) para eliminar
/// a fadiga ocular em sessões prolongadas de treino noturno e garantir o Pop-Out
/// pré-atencional de Anne Treisman em lances críticos.
class AppColors {
  AppColors._();

  // Fundo e Superfícies (OLED Deep Dark)
  static const Color background = Color(0xFF0B0F17); // Obsidian Dark
  static const Color surface = Color(0xFF151C28); // Slate Noturno
  static const Color surfaceElevated = Color(0xFF1E2838); // Borda e cards destacados
  static const Color border = Color(0xFF1E2838);
  static const Color surfaceHover = Color(0xFF28354A);

  // Acentos de Alta Energia (Pop-Out Visual)
  static const Color primaryCyan = Color(0xFF00E5FF); // Ciano Elétrico (Atenção primária)
  static const Color primaryCyanDark = Color(0xFF00B4D8);
  static const Color secondaryAmber = Color(0xFFFFB300); // Dourado de estrelas / XP
  static const Color accentEmerald = Color(0xFF00E676); // Lance Melhor / Acerto

  // Classificação Didática de Lances & Alertas
  static const Color moveBrilliant = Color(0xFF26C6DA); // Ciano Turquesa (!!)
  static const Color moveGreat = Color(0xFF42A5F5); // Azul Cobalto (!)
  static const Color moveBest = Color(0xFF00E676); // Verde Esmeralda (★)
  static const Color moveExcellent = Color(0xFF81C784); // Verde Claro (✓)
  static const Color moveInaccuracy = Color(0xFFFFD54F); // Amarelo (?!)
  static const Color moveMistake = Color(0xFFFF9800); // Laranja (?)
  static const Color moveBlunder = Color(0xFFFF1744); // Carmesim Neon (??)
  static const Color moveMiss = Color(0xFFE040FB); // Magenta / Oportunidade Perdida

  // Tipografia & Ícones
  static const Color textPrimary = Color(0xFFF8FAFC); // Quase branco de altíssimo contraste
  static const Color textSecondary = Color(0xFF94A3B8); // Cinza neutro legível
  static const Color textMuted = Color(0xFF64748B); // Detalhes e coordenadas

  // Tabuleiros Clássicos
  static const Color boardGreenLight = Color(0xFFEEEED2);
  static const Color boardGreenDark = Color(0xFF769656);

  static const Color boardWoodLight = Color(0xFFF0D9B5);
  static const Color boardWoodDark = Color(0xFFB58863);

  static const Color boardDarkLight = Color(0xFF333E50);
  static const Color boardDarkDark = Color(0xFF1E2530);

  // Destaques no Tabuleiro
  static const Color squareSelected = Color(0x9900E5FF);
  static const Color squareLegalMoveDot = Color(0x6600E5FF);
  static const Color squareLegalMoveRing = Color(0xAA00E5FF);
  static const Color squareLastMove = Color(0x55FACC15);
  static const Color squareInCheck = Color(0xCCFF1744);
}
