import 'package:flutter/material.dart';
import 'app_colors.dart';

enum BoardVisualTheme {
  tournamentGreen,
  nobleWood,
  obsidianModern,
}

class ChessTheme {
  final BoardVisualTheme visualTheme;
  final Color lightSquareColor;
  final Color darkSquareColor;
  final Color backgroundColor;
  final Color surfaceColor;

  const ChessTheme({
    required this.visualTheme,
    required this.lightSquareColor,
    required this.darkSquareColor,
    this.backgroundColor = AppColors.background,
    this.surfaceColor = AppColors.surface,
  });

  static const ChessTheme tournamentGreen = ChessTheme(
    visualTheme: BoardVisualTheme.tournamentGreen,
    lightSquareColor: AppColors.boardGreenLight,
    darkSquareColor: AppColors.boardGreenDark,
  );

  static const ChessTheme nobleWood = ChessTheme(
    visualTheme: BoardVisualTheme.nobleWood,
    lightSquareColor: AppColors.boardWoodLight,
    darkSquareColor: AppColors.boardWoodDark,
  );

  static const ChessTheme obsidianModern = ChessTheme(
    visualTheme: BoardVisualTheme.obsidianModern,
    lightSquareColor: AppColors.boardDarkLight,
    darkSquareColor: AppColors.boardDarkDark,
  );

  ThemeData toThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: AppColors.primaryCyan,
      cardColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.secondaryAmber,
        surface: AppColors.surface,
        error: AppColors.moveBlunder,
      ),
    );
  }
}
