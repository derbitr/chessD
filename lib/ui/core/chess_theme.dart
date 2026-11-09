import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppThemeMode {
  dark,
  light,
}

enum BoardVisualTheme {
  tournamentGreen(
    id: 'tournamentGreen',
    name: 'Verde Torneio FIDE',
    lightColor: Color(0xFFEEEED2),
    darkColor: Color(0xFF769656),
    description: 'Padrão clássico internacional de torneios oficiais.',
  ),
  nobleWood(
    id: 'nobleWood',
    name: 'Nogueira & Carvalho Nobre',
    lightColor: Color(0xFFF0D9B5),
    darkColor: Color(0xFFB58863),
    description: 'Madeira tradicional quente e aconchegante.',
  ),
  midnightOcean(
    id: 'midnightOcean',
    name: 'Oceano Meia-Noite',
    lightColor: Color(0xFFDCE8EF),
    darkColor: Color(0xFF4E7A99),
    description: 'Tons náuticos e serenos de azul marinho e gelo.',
  ),
  royalAmethyst(
    id: 'royalAmethyst',
    name: 'Ametista Real',
    lightColor: Color(0xFFEAE2F3),
    darkColor: Color(0xFF7A5299),
    description: 'Púrpura imperial sofisticada com lavanda suave.',
  ),
  sunsetCoral(
    id: 'sunsetCoral',
    name: 'Coral & Terracota',
    lightColor: Color(0xFFF5D6D6),
    darkColor: Color(0xFFB84A4A),
    description: 'Gradiente quente inspirado no pôr do sol.',
  ),
  cyberOnyx(
    id: 'cyberOnyx',
    name: 'Vidro Ônix & Grafite',
    lightColor: Color(0xFF333E50),
    darkColor: Color(0xFF1E2530),
    description: 'Dark Glass futurista de altíssimo contraste.',
  ),
  pastelMint(
    id: 'pastelMint',
    name: 'Menta Pastel',
    lightColor: Color(0xFFE2F0D9),
    darkColor: Color(0xFF5B8A61),
    description: 'Verde herbal relaxante que reduz o cansaço visual.',
  ),
  monochrome(
    id: 'monochrome',
    name: 'Monocromático Estrito',
    lightColor: Color(0xFFFFFFFF),
    darkColor: Color(0xFF222222),
    description: 'Preto e branco minimalista de máxima nitidez.',
  );

  final String id;
  final String name;
  final Color lightColor;
  final Color darkColor;
  final String description;

  const BoardVisualTheme({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.description,
  });
}

enum PieceVisualTheme {
  classicStaunton(
    id: 'classicStaunton',
    name: 'Clássico Staunton',
    whiteColor: Color(0xFFFFFFFF),
    blackColor: Color(0xFF18181B),
    description: 'Peças tradicionais em branco puro e grafite.',
  ),
  goldAndSilver(
    id: 'goldAndSilver',
    name: 'Ouro & Titânio Imperial',
    whiteColor: Color(0xFFFFD700),
    blackColor: Color(0xFF94A3B8),
    description: 'Ouro dourado lustroso contra prata metálica.',
  ),
  cyberNeon(
    id: 'cyberNeon',
    name: 'Cyber Neon Fluo',
    whiteColor: Color(0xFF00E5FF),
    blackColor: Color(0xFFFF1493),
    description: 'Ciano fluorescente elétrico contra magenta neon.',
  ),
  ivoryAndEbony(
    id: 'ivoryAndEbony',
    name: 'Marfim & Ébano Quente',
    whiteColor: Color(0xFFFFFBEB),
    blackColor: Color(0xFF3E2723),
    description: 'Madeiras nobres de marfim antigo e ébano escuro.',
  ),
  emeraldAndOnyx(
    id: 'emeraldAndOnyx',
    name: 'Esmeralda & Ônix',
    whiteColor: Color(0xFFA7F3D0),
    blackColor: Color(0xFF09090B),
    description: 'Menta esmeralda translúcida contra ônix absoluto.',
  );

  final String id;
  final String name;
  final Color whiteColor;
  final Color blackColor;
  final String description;

  const PieceVisualTheme({
    required this.id,
    required this.name,
    required this.whiteColor,
    required this.blackColor,
    required this.description,
  });
}

enum AccentVisualTheme {
  chessGreen(
    id: 'chessGreen',
    name: 'Verde Chess.com',
    color: Color(0xFF81B64C),
  ),
  gold(
    id: 'gold',
    name: 'Dourado Torneio',
    color: Color(0xFFE5A823),
  ),
  cyan(
    id: 'cyan',
    name: 'Ciano Elétrico',
    color: Color(0xFF00B4D8),
  ),
  emerald(
    id: 'emerald',
    name: 'Verde Esmeralda',
    color: Color(0xFF00E676),
  ),
  amber(
    id: 'amber',
    name: 'Dourado Âmbar',
    color: Color(0xFFFFB300),
  ),
  violet(
    id: 'violet',
    name: 'Violeta Tecnológico',
    color: Color(0xFF8B5CF6),
  ),
  crimson(
    id: 'crimson',
    name: 'Carmesim Rubi',
    color: Color(0xFFEF4444),
  ),
  royalBlue(
    id: 'royalBlue',
    name: 'Azul Safira',
    color: Color(0xFF3B82F6),
  );

  final String id;
  final String name;
  final Color color;

  const AccentVisualTheme({
    required this.id,
    required this.name,
    required this.color,
  });
}

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();

  ThemeController._();

  AppThemeMode _themeMode = AppThemeMode.dark;
  BoardVisualTheme _boardTheme = BoardVisualTheme.tournamentGreen;
  PieceVisualTheme _pieceTheme = PieceVisualTheme.classicStaunton;
  AccentVisualTheme _accentTheme = AccentVisualTheme.chessGreen;

  AppThemeMode get themeMode => _themeMode;
  BoardVisualTheme get boardTheme => _boardTheme;
  PieceVisualTheme get pieceTheme => _pieceTheme;
  AccentVisualTheme get accentTheme => _accentTheme;

  bool get isDark => _themeMode == AppThemeMode.dark;
  bool get isDarkMode => isDark;
  Color get lightSquareColor => _boardTheme.lightColor;
  Color get darkSquareColor => _boardTheme.darkColor;
  Color get whitePieceColor => _pieceTheme.whiteColor;
  Color get blackPieceColor => _pieceTheme.blackColor;
  Color get accentColor => _accentTheme.color;

  Color get scaffoldBackground => isDark ? const Color(0xFF262522) : const Color(0xFFF8FAFC);
  Color get surfaceColor => isDark ? const Color(0xFF2B2927) : const Color(0xFFFFFFFF);
  Color get surfaceElevatedColor => isDark ? const Color(0xFF383634) : const Color(0xFFF1F5F9);
  Color get borderColor => isDark ? const Color(0xFF383634) : const Color(0xFFE2E8F0);
  Color get textPrimary => isDark ? const Color(0xFFF7F7F6) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFFA3A29E) : const Color(0xFF475569);

  void setThemeMode(AppThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setBoardTheme(BoardVisualTheme theme) {
    if (_boardTheme != theme) {
      _boardTheme = theme;
      notifyListeners();
    }
  }

  void setPieceTheme(PieceVisualTheme theme) {
    if (_pieceTheme != theme) {
      _pieceTheme = theme;
      notifyListeners();
    }
  }

  void setAccentTheme(AccentVisualTheme theme) {
    if (_accentTheme != theme) {
      _accentTheme = theme;
      notifyListeners();
    }
  }

  void resetDefaults() {
    _themeMode = AppThemeMode.dark;
    _boardTheme = BoardVisualTheme.tournamentGreen;
    _pieceTheme = PieceVisualTheme.classicStaunton;
    _accentTheme = AccentVisualTheme.chessGreen;
    notifyListeners();
  }

  ThemeData toThemeData() {
    if (isDark) {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: scaffoldBackground,
        primaryColor: accentColor,
        cardColor: surfaceColor,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: const Color(0xFFFFB300),
          surface: surfaceColor,
          error: AppColors.moveBlunder,
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: scaffoldBackground,
        primaryColor: accentColor,
        cardColor: surfaceColor,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        colorScheme: ColorScheme.light(
          primary: accentColor,
          secondary: const Color(0xFFFFB300),
          surface: surfaceColor,
          error: AppColors.moveBlunder,
        ),
      );
    }
  }
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
    lightSquareColor: Color(0xFFEEEED2),
    darkSquareColor: Color(0xFF769656),
  );

  static const ChessTheme nobleWood = ChessTheme(
    visualTheme: BoardVisualTheme.nobleWood,
    lightSquareColor: Color(0xFFF0D9B5),
    darkSquareColor: Color(0xFFB58863),
  );

  static const ChessTheme obsidianModern = ChessTheme(
    visualTheme: BoardVisualTheme.cyberOnyx,
    lightSquareColor: Color(0xFF333E50),
    darkSquareColor: Color(0xFF1E2530),
  );

  ThemeData toThemeData() {
    return ThemeController.instance.toThemeData();
  }
}
