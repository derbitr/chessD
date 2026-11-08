import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/wifi_cast_server.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import 'package:chess_d/ui/features/board/coordinate_trainer.dart';
import 'package:chess_d/ui/features/board/pass_and_play_screen.dart';
import 'package:chess_d/ui/features/game/bot_game_screen.dart';
import 'package:chess_d/ui/features/game/bot_studio_screen.dart';
import 'package:chess_d/ui/features/learning/learning_track_screen.dart';
import 'package:chess_d/ui/features/training/infinite_puzzles_screen.dart';
import 'package:chess_d/ui/features/training/puzzle_ladder_screen.dart';
import 'package:chess_d/ui/features/training/retry_mistakes_screen.dart';
import 'package:chess_d/ui/features/analysis/game_review_screen.dart';
import 'package:chess_d/ui/features/analysis/anti_cheat_audit_screen.dart';
import 'package:chess_d/ui/features/openings/opening_explorer_screen.dart';
import 'package:chess_d/ui/features/repertoire/repertoire_trainer_screen.dart';
import 'package:chess_d/ui/features/tournament/tournament_manager_screen.dart';
import 'package:chess_d/ui/features/settings/offline_packs_screen.dart';
import 'package:chess_d/ui/features/settings/theme_customization_screen.dart';
import 'package:chess_d/ui/features/multiplayer/online_multiplayer_screen.dart';
import 'package:chess_d/ui/features/settings/help_support_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessDApp());
}

class ChessDApp extends StatelessWidget {
  const ChessDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'chessD',
          debugShowCheckedModeBanner: false,
          theme: ThemeController.instance.toThemeData(),
          home: const MainHubScreen(),
        );
      },
    );
  }
}

class MainHubScreen extends StatefulWidget {
  const MainHubScreen({super.key});

  @override
  State<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen> {
  ChessRustFfi? ffi;
  late final WifiCastServer castServer;
  bool isRustReady = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    castServer = WifiCastServer();
    _initRustCore();
  }

  @override
  void dispose() {
    castServer.stop();
    super.dispose();
  }

  void _initRustCore() {
    try {
      final engine = ChessRustFfi();
      final testGame = engine.newGame();
      engine.getStatus(testGame);
      engine.freeGame(testGame);

      setState(() {
        ffi = engine;
        isRustReady = true;
      });
    } catch (_) {
      setState(() {
        isRustReady = false;
      });
    }
  }

  void _showPlayModal() {
    if (!isRustReady || ffi == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeController.instance.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final theme = ThemeController.instance;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Escolha o Modo de Jogo',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _buildPlayOption(
                  icon: Icons.smart_toy,
                  title: 'Partida contra Bot',
                  subtitle: 'Jogue contra bots calibrados de Elo 300 a 2400',
                  color: const Color(0xFF81B64C),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BotGameScreen(ffi: ffi!, botElo: 600, botName: 'O Trilheiro (600)')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayOption(
                  icon: Icons.people_alt,
                  title: 'Pass & Play (2 Jogadores)',
                  subtitle: 'Dispute presencialmente no mesmo celular com relógio duplo',
                  color: AppColors.secondaryAmber,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PassAndPlayScreen(ffi: ffi!)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayOption(
                  icon: Icons.wifi,
                  title: 'Multiplayer Online P2P',
                  subtitle: 'Jogue online direto com outro jogador via WebRTC',
                  color: AppColors.primaryCyan,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnlineMultiplayerScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayOption(
                  icon: Icons.casino,
                  title: 'Xadrez 960 (Fischer Random)',
                  subtitle: 'Posição inicial aleatória oficial de Fischer',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final (seed, fen) = ffi!.getRandomChess960();
                    final game960 = ffi!.newGameFromFen(fen);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BotGameScreen(ffi: ffi!, botName: 'Xadrez 960 (#$seed)', botElo: 1200),
                      ),
                    ).then((_) => ffi!.freeGame(game960));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = ThemeController.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceElevatedColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const PawnLogo(size: 26, color: Color(0xFF81B64C), hasBadge: true),
            const SizedBox(width: 10),
            Text(
              'chessD',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          // Badges de Status (Streak e XP) no Estilo Chess.com
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceElevatedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text('0', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceElevatedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, color: AppColors.primaryCyan, size: 16),
                const SizedBox(width: 4),
                Text('100', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: theme.accentColor),
            tooltip: 'Personalização Visual',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeTab(),
            _buildPuzzlesTab(),
            _buildLearnTab(),
            _buildWatchTab(),
            _buildMoreTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.surfaceColor,
        selectedItemColor: const Color(0xFF81B64C),
        unselectedItemColor: theme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: PawnLogo(size: 22, color: Colors.grey, hasBadge: false),
            activeIcon: PawnLogo(size: 22, color: Color(0xFF81B64C), hasBadge: false),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension),
            label: 'Problemas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Assistir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  // TAB 1: INÍCIO (Estilo Idêntico ao Chess.com Mobile)
  Widget _buildHomeTab() {
    final theme = ThemeController.instance;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Botão Hero Gigante "JOGAR" no Verde Canônico do Chess.com (#81B64C)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _showPlayModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81B64C),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Jogar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Carrossel de Destaques Rápidos (Problemas, Diário, Bots, Torneio)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Card Problemas
              _buildFeaturedCard(
                title: 'Problemas',
                subtitle: 'Treino Tático Livre',
                badgeText: 'Resolva!',
                icon: Icons.extension,
                accentColor: const Color(0xFF81B64C),
                onTap: () {
                  if (ffi != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfinitePuzzlesScreen(ffi: ffi!)));
                  }
                },
              ),
              const SizedBox(width: 12),

              // Card Problema Diário
              _buildFeaturedCard(
                title: 'Problema Diário',
                subtitle: 'Desafio de Hoje',
                badgeText: 'Jogar',
                icon: Icons.calendar_today,
                accentColor: AppColors.secondaryAmber,
                onTap: () {
                  if (ffi != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfinitePuzzlesScreen(ffi: ffi!)));
                  }
                },
              ),
              const SizedBox(width: 12),

              // Card Jogar com Bots
              _buildFeaturedCard(
                title: 'Jogar com Bots',
                subtitle: 'Elo 300 a 2400',
                badgeText: 'Desafiar',
                icon: Icons.smart_toy,
                accentColor: AppColors.primaryCyan,
                onTap: () {
                  if (ffi != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BotGameScreen(ffi: ffi!, botElo: 600, botName: 'O Trilheiro (600)')));
                  }
                },
              ),
              const SizedBox(width: 12),

              // Card Torneios Suíços
              _buildFeaturedCard(
                title: 'Torneios',
                subtitle: 'Com Níveis de Elo',
                badgeText: 'Entrar',
                icon: Icons.emoji_events,
                accentColor: Colors.amberAccent,
                onTap: () {
                  if (ffi != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentManagerScreen(ffi: ffi!)));
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Grade de Ratings (Bullet, Blitz, Rápido, Diário)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ratings', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text('Ver todos', style: TextStyle(color: theme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildRatingItem(icon: Icons.flash_on, title: 'Bullet', rating: '1200', color: Colors.orange),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.bolt, title: 'Blitz', rating: '1200', color: Colors.amber),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.timer, title: 'Rápido', rating: '1200', color: AppColors.accentEmerald),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.wb_sunny, title: 'Diário', rating: '1200', color: Colors.orangeAccent),
          ],
        ),

        const SizedBox(height: 24),

        // Lista de Bots com Elo (Idêntico à gravação do Chess.com: 300, 600, 1100, 1600)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jogar com Bots', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text('Elo 300 a 2400', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        _buildBotChallengeItem(name: 'O Ornitólogo', elo: 300, personality: 'Iniciante Curioso', personalityId: 0),
        _buildBotChallengeItem(name: 'O Trilheiro', elo: 600, personality: 'Casual & Amigável', personalityId: 0),
        _buildBotChallengeItem(name: 'Estrategista', elo: 1100, personality: 'Equilibrado de Clube', personalityId: 0),
        _buildBotChallengeItem(name: 'Valkyrie', elo: 1200, personality: 'Agressiva & Tática', personalityId: 1),
        _buildBotChallengeItem(name: 'Mestre Local', elo: 1600, personality: 'Posicional & Firme', personalityId: 2),
      ],
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = ThemeController.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF81B64C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem({
    required IconData icon,
    required String title,
    required String rating,
    required Color color,
  }) {
    final theme = ThemeController.instance;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
            const SizedBox(height: 2),
            Text(rating, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotChallengeItem({
    required String name,
    required int elo,
    required String personality,
    required int personalityId,
  }) {
    final theme = ThemeController.instance;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.primaryCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.surfaceElevatedColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$elo', style: const TextStyle(color: Color(0xFF81B64C), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                Text(personality, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (ffi != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BotGameScreen(ffi: ffi!, botElo: elo, botName: '$name ($elo)', botPersonality: personalityId)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81B64C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Jogar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // TAB 2: PROBLEMAS
  Widget _buildPuzzlesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(
          title: 'Quebra-Cabeças Infinitos',
          subtitle: 'Treino ilimitado offline com calibração adaptativa de Elo e multiplicador de combo.',
          icon: Icons.extension,
          accentColor: const Color(0xFF81B64C),
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfinitePuzzlesScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Escada de Problemas (Rush 3 Vidas)',
          subtitle: 'Modo sobrevivência: resolva problemas de dificuldade crescente até acumular 3 erros.',
          icon: Icons.trending_up,
          accentColor: AppColors.secondaryAmber,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PuzzleLadderScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Treino de Erros Próprios',
          subtitle: 'Recurso Diamante gratuito: repita seus lances errados e aprenda a refutação correta.',
          icon: Icons.replay,
          accentColor: AppColors.accentEmerald,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => RetryMistakesScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Treinador de Coordenadas',
          subtitle: 'Desafio de 30 segundos contra o relógio para dominar a visão de casas no tabuleiro.',
          icon: Icons.speed,
          accentColor: AppColors.primaryCyan,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoordinateTrainerScreen()));
          },
        ),
      ],
    );
  }

  // TAB 3: APRENDER
  Widget _buildLearnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(
          title: 'Trilha de Maestria (Estilo Duolingo)',
          subtitle: 'Navegue pelo caminho senoidal com lições guiadas, mini-aulas e baterias táticas.',
          icon: Icons.alt_route,
          accentColor: const Color(0xFF81B64C),
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearningTrackScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Treinador de Repertório (SM-2)',
          subtitle: 'Memorização científica com repetição espaçada SuperMemo para linhas de abertura.',
          icon: Icons.psychology,
          accentColor: AppColors.secondaryAmber,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => RepertoireTrainerScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Explorador de Aberturas (ECO)',
          subtitle: 'Catálogo profundo de linhas mestras, variantes teóricas e estatísticas de vitória.',
          icon: Icons.menu_book,
          accentColor: AppColors.primaryCyan,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => OpeningExplorerScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Central de Ajuda & Guia FIDE',
          subtitle: 'Manual de regras oficiais FIDE (roque, en passant), manual do app e FAQ completo.',
          icon: Icons.help_outline,
          accentColor: Colors.deepPurpleAccent,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
          },
        ),
      ],
    );
  }

  // TAB 4: ASSISTIR & ANÁLISE
  Widget _buildWatchTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(
          title: 'Revisão de Partida & Coach IA',
          subtitle: 'Análise profunda CAPS2, gráfico de vantagem, detecção de tilt e cartões virais.',
          icon: Icons.analytics,
          accentColor: const Color(0xFF81B64C),
          onTap: () {
            if (ffi != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GameReviewScreen(
                    ffi: ffi!,
                    movesPlayedUci: const [
                      'e2e4', 'e7e5', 'g1f3', 'd7d6', 'd2d4', 'c8g4', 'd4e5', 'g4f3',
                      'd1f3', 'd6e5', 'f1c4', 'g8f6', 'f3b3', 'd8e7', 'b1c3', 'c7c6',
                      'c1g5', 'b7b5', 'c3b5', 'c6b5', 'c4b5', 'b8d7', 'e1c1', 'a8d8',
                      'd1d7', 'd8d7', 'h1d1', 'e7e6', 'b5d7', 'f6d7', 'b3b8', 'd7b8',
                      'd1d8',
                    ],
                    playerColor: 'white',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Perícia Forense Anti-Cheat',
          subtitle: 'Auditoria estatística FIDE/Regan para detecção de lances assistidos por motor.',
          icon: Icons.security,
          accentColor: AppColors.moveBlunder,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => AntiCheatAuditScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Acervo Offline & Wi-Fi Cast',
          subtitle: 'Gerenciador de 4.2M+ puzzles Zstandard e espelhamento ao vivo para Smart TV.',
          icon: Icons.cast_connected,
          accentColor: AppColors.primaryCyan,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfflinePacksScreen(castServer: castServer)));
          },
        ),
      ],
    );
  }

  // TAB 5: MAIS (Recursos Especiais, Torneios, Paletas)
  Widget _buildMoreTab() {
    final theme = ThemeController.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(
          title: 'Torneios (Sistema Suíço FIDE)',
          subtitle: 'Organize campeonatos com níveis de Elo: Iniciante (300-800), Amador, Mestres ou Personalizado.',
          icon: Icons.emoji_events,
          accentColor: Colors.amberAccent,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentManagerScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Estúdio de Criação de Bots',
          subtitle: 'Crie oponentes personalizados com personalidades táticas, posicional ou clássica.',
          icon: Icons.tune,
          accentColor: AppColors.primaryCyan,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => BotStudioScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Multiplayer Online P2P',
          subtitle: 'Jogue online via WebRTC direto com STUN do Google. 100% gratuito e sem custos.',
          icon: Icons.wifi_tethering,
          accentColor: AppColors.accentEmerald,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnlineMultiplayerScreen()));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Personalização Visual & Paletas',
          subtitle: 'Alterne entre Modo Claro e Noite, escolha entre 8 paletas de tabuleiro e 5 estilos de peças.',
          icon: Icons.palette,
          accentColor: theme.accentColor,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Pass & Play (2 Jogadores)',
          subtitle: 'Jogue presencialmente no mesmo aparelho com relógio digital duplo espelhado.',
          icon: Icons.people_alt,
          accentColor: AppColors.secondaryAmber,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PassAndPlayScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Xadrez 960 (Fischer Random)',
          subtitle: 'Sorteio aleatório de uma das 960 posições oficiais de Bobby Fischer.',
          icon: Icons.casino,
          accentColor: Colors.purpleAccent,
          onTap: () {
            if (ffi != null) {
              final (seed, fen) = ffi!.getRandomChess960();
              final game960 = ffi!.newGameFromFen(fen);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BotGameScreen(ffi: ffi!, botName: 'Xadrez 960 (#$seed)', botElo: 1400),
                ),
              ).then((_) => ffi!.freeGame(game960));
            }
          },
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = ThemeController.instance;
    return InkWell(
      onTap: isRustReady ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
              ),
              child: Center(
                child: Icon(icon, color: accentColor, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.textSecondary.withOpacity(0.5), size: 22),
          ],
        ),
      ),
    );
  }
}
