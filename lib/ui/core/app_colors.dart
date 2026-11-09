import 'package:flutter/material.dart';

/// Paleta de Cores Canônica chessD (Dossiê RPA 10 - Chess.com Design System)
/// Extraída diretamente dos tokens e bounds do Chess.com oficial (1080x2400)
class AppColors {
  AppColors._();

  // Fundo e Superfícies (Chess.com Slate Dark Oficial - Dossiê RPA 10)
  static const Color background = Color(0xFF262522); // Background Canônico Oled Slate
  static const Color surface = Color(0xFF2B2927); // Superfície de Cards e Painéis
  static const Color surfaceElevated = Color(0xFF383634); // Borda e painéis elevados
  static const Color border = Color(0xFF383634);
  static const Color surfaceHover = Color(0xFF413D3B);

  // Acentos Canônicos Chess.com
  static const Color chessGreen = Color(0xFF81B64C); // Verde Canônico de Ação (Chess.com)
  static const Color primaryGreen = Color(0xFF81B64C);
  static const Color accentEmerald = Color(0xFF81B64C);
  static const Color chessGold = Color(0xFFE5A823); // Dourado de rating / blitz / coroas
  static const Color secondaryAmber = Color(0xFFE5A823);
  static const Color primaryCyan = Color(0xFF81B64C); // Canônico Verde Chess.com
  static const Color primaryCyanDark = Color(0xFF5E8B34); // Verde Escuro de Sombra 3D

  // Classificação Didática de Lances & Alertas (Dossiê RPA 10)
  static const Color moveBrilliant = Color(0xFF26C6DA); // Ciano Turquesa (!!)
  static const Color moveGreat = Color(0xFF42A5F5); // Azul Cobalto (!)
  static const Color moveBest = Color(0xFF81B64C); // Verde Chess.com (★)
  static const Color moveExcellent = Color(0xFF81C784); // Verde Claro (✓)
  static const Color moveInaccuracy = Color(0xFFFFD54F); // Amarelo (?!)
  static const Color moveMistake = Color(0xFFFF9800); // Laranja (?)
  static const Color moveBlunder = Color(0xFFE63946); // Carmesim Forense (??)
  static const Color moveMiss = Color(0xFFE040FB); // Magenta / Oportunidade Perdida

  // Tipografia & Ícones (Tokens Chess.com Oficiais)
  static const Color textPrimary = Color(0xFFF7F7F6); // Branco Suave de Altíssimo Contraste
  static const Color textSecondary = Color(0xFFA3A29E); // Muted Gray Oficial
  static const Color textMuted = Color(0xFF8B8987); // Detalhes e coordenadas

  // Tabuleiros Clássicos Oficiais
  static const Color boardGreenLight = Color(0xFFEEEED2);
  static const Color boardGreenDark = Color(0xFF769656);

  static const Color boardWoodLight = Color(0xFFF0D9B5);
  static const Color boardWoodDark = Color(0xFFB58863);

  static const Color boardDarkLight = Color(0xFF333E50);
  static const Color boardDarkDark = Color(0xFF1E2530);

  // Destaques no Tabuleiro (Tokens Dossiê RPA 10)
  static const Color squareSelected = Color(0xA6BBCA2B); // #BBCA2B com 0.65 opacidade
  static const Color squareLastMove = Color(0x6BF7F769); // #F7F769 com 0.42 opacidade
  static const Color squareLegalMoveDot = Color(0x38000000); // Preto 0.22 opacidade
  static const Color squareLegalMoveRing = Color(0x40000000); // Preto 0.25 anel
  static const Color squareInCheck = Color(0xCCE63946); // Vermelho xeque
}
