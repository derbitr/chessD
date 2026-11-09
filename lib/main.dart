import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chess_d/services/app_update_service.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/player_stats_service.dart';
import 'package:chess_d/services/system_bridge.dart';
import 'package:chess_d/services/user_mistakes_service.dart';
import 'package:chess_d/services/wifi_cast_server.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import 'package:chess_d/ui/core/trail_connector.dart';
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

class _MainHubScreenState extends State<MainHubScreen> with WidgetsBindingObserver {
  ChessRustFfi? ffi;
  late final WifiCastServer castServer;
  bool isRustReady = false;
  int _currentTabIndex = 0;
  AppUpdateInfo? _availableUpdate;
  bool _dismissedUpdate = false;
  DateTime? _lastUpdateCheckAt;
  String? _notifiedVersionTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    castServer = WifiCastServer();
    PlayerStatsService.instance.loadSync();
    UserMistakesService.loadSync();
    _initRustCore();
    SystemBridge.requestAndroidNotificationPermission();
    _checkAppUpdateSilently();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _availableUpdate == null) {
      final elapsed = _lastUpdateCheckAt == null
          ? const Duration(hours: 1)
          : DateTime.now().difference(_lastUpdateCheckAt!);
      if (elapsed >= const Duration(minutes: 15)) {
        _checkAppUpdateSilently();
      }
    }
  }

  Future<void> _checkAppUpdateSilently() async {
    _lastUpdateCheckAt = DateTime.now();
    final outcome = await AppUpdateService.checkForUpdateDetailed();
    final info = outcome.info;
    if (mounted && info != null && info.hasUpdate) {
      setState(() {
        _availableUpdate = info;
        _dismissedUpdate = false;
      });
      if (_notifiedVersionTag != info.latestVersion) {
        _notifiedVersionTag = info.latestVersion;
        SystemBridge.showAndroidUpdateNotification(
          title: 'chessD ${info.latestVersion} disponível!',
          body: 'Nova versão lançada com melhorias. Toque para baixar agora.',
          url: info.downloadUrl,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: ThemeController.instance.surfaceElevatedColor,
              duration: const Duration(seconds: 6),
              content: Text(
                'Atualização ${info.latestVersion} disponível para baixar!',
                style: TextStyle(color: ThemeController.instance.textPrimary, fontWeight: FontWeight.w600),
              ),
              action: SnackBarAction(
                label: 'Baixar',
                textColor: AppColors.chessGreen,
                onPressed: () => _openUpdateUrl(info.downloadUrl),
              ),
            ),
          );
        });
      }
    }
  }

  Future<void> _openUpdateUrl(String url) async {
    final opened = await SystemBridge.openExternalUrl(url);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Link da atualização copiado para a área de transferência!'),
        ),
      );
    }
  }

  Future<void> _manualCheckForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeController.instance.surfaceColor,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.chessGreen),
            const SizedBox(width: 16),
            Text('Buscando atualizações...', style: TextStyle(color: ThemeController.instance.textPrimary)),
          ],
        ),
      ),
    );

    final outcome = await AppUpdateService.checkForUpdateDetailed();
    final info = outcome.info;
    if (!mounted) return;
    Navigator.of(context).pop();

    if (info != null && info.hasUpdate) {
      setState(() {
        _availableUpdate = info;
        _dismissedUpdate = false;
      });
      if (_notifiedVersionTag != info.latestVersion) {
        _notifiedVersionTag = info.latestVersion;
        SystemBridge.showAndroidUpdateNotification(
          title: 'chessD ${info.latestVersion} disponível!',
          body: 'Nova versão lançada com melhorias. Toque para baixar agora.',
          url: info.downloadUrl,
        );
      }
      _showUpdateDialog(info);
    } else if (info != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeController.instance.surfaceColor,
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.chessGreen, size: 24),
              const SizedBox(width: 8),
              Text('Versão Mais Recente', style: TextStyle(color: ThemeController.instance.textPrimary, fontSize: 18)),
            ],
          ),
          content: Text(
            'Você já está utilizando a versão mais recente do chessD (${AppUpdateService.currentVersion}).',
            style: TextStyle(color: ThemeController.instance.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.chessGreen),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeController.instance.surfaceColor,
          title: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.chessGold, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Falha ao Verificar',
                  style: TextStyle(color: ThemeController.instance.textPrimary, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            outcome.errorMessage ?? 'Não foi possível consultar o GitHub no momento. Verifique sua conexão com a internet.',
            style: TextStyle(color: ThemeController.instance.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Fechar', style: TextStyle(color: ThemeController.instance.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openUpdateUrl(AppUpdateService.repoReleasesPage);
              },
              icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
              label: const Text('Abrir Releases', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.chessGreen),
            ),
          ],
        ),
      );
    }
  }

  void _showUpdateDialog(AppUpdateInfo info) {
    final notesPreview = info.releaseNotes.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeController.instance.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const PawnLogo(size: 26, color: AppColors.chessGreen, hasBadge: true),
            const SizedBox(width: 10),
            Text('Nova Atualização!', style: TextStyle(color: ThemeController.instance.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versão ${info.latestVersion} disponível para download.',
                style: TextStyle(color: ThemeController.instance.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Versão instalada: ${info.currentVersion}\nNovidades e correções estão prontas para serem instaladas no seu dispositivo.',
                style: TextStyle(color: ThemeController.instance.textSecondary, fontSize: 13),
              ),
              if (notesPreview.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeController.instance.surfaceElevatedColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ThemeController.instance.borderColor),
                  ),
                  child: Text(
                    notesPreview.length > 350 ? '${notesPreview.substring(0, 350)}...' : notesPreview,
                    style: TextStyle(color: ThemeController.instance.textSecondary, fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Depois', style: TextStyle(color: ThemeController.instance.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openUpdateUrl(info.downloadUrl);
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('Baixar Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.chessGreen),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                  subtitle: 'Jogue contra robôs calibrados de Elo 300 a 2400',
                  color: AppColors.chessGreen,
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
                  color: AppColors.chessGold,
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
                  color: AppColors.chessGreen,
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

  void _showPuzzlesModesModal() {
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
                  'Modos de Quebra-Cabeças',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _buildPlayOption(
                  icon: Icons.trending_up,
                  title: 'Escada de Problemas (Rush 3 Vidas)',
                  subtitle: 'Modo sobrevivência: resolva problemas até errar 3 vezes',
                  color: AppColors.chessGold,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PuzzleLadderScreen(ffi: ffi!)));
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayOption(
                  icon: Icons.replay,
                  title: 'Treino de Erros Próprios',
                  subtitle: 'Refaça suas gafes reais de partidas e aprenda a refutação',
                  color: AppColors.chessGreen,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => RetryMistakesScreen(ffi: ffi!)));
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayOption(
                  icon: Icons.speed,
                  title: 'Treinador de Coordenadas',
                  subtitle: 'Treine a visão instantânea de casas no tabuleiro em 30 segundos',
                  color: AppColors.primaryCyan,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoordinateTrainerScreen()));
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
            const PawnLogo(size: 26, color: AppColors.chessGreen, hasBadge: true),
            const SizedBox(width: 10),
            Text(
              'chessD',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          if (_availableUpdate != null)
            IconButton(
              tooltip: 'Atualização ${_availableUpdate!.latestVersion} disponível',
              onPressed: () => _showUpdateDialog(_availableUpdate!),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.chessGold),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.chessGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        child: Column(
          children: [
            Expanded(
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

            // Botão Fixo Canônico "Jogar" acima da BottomNavigationBar (Aba Início)
            if (_currentTabIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _showPlayModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chessGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Jogar',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Barra Fixa Canônica "Resolva problemas" (Aba Problemas)
            if (_currentTabIndex == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _showPuzzlesModesModal,
                      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.surfaceColor,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (ffi != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InfinitePuzzlesScreen(
                                    ffi: ffi!,
                                    trailNode: PlayerStatsService.instance.puzzleTrailNode,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.chessGreen,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 26, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Resolva problemas',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.surfaceColor,
        selectedItemColor: AppColors.chessGreen,
        unselectedItemColor: theme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: PawnLogo(size: 22, color: Colors.grey, hasBadge: false),
            activeIcon: PawnLogo(size: 22, color: AppColors.chessGreen, hasBadge: false),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension_outlined),
            activeIcon: Icon(Icons.extension),
            label: 'Problemas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Aprender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility_outlined),
            activeIcon: Icon(Icons.visibility),
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

  // TAB 1: INÍCIO (Layout Oficial Idêntico ao Chess.com Mobile)
  Widget _buildHomeTab() {
    final theme = ThemeController.instance;

    return AnimatedBuilder(
      animation: PlayerStatsService.instance,
      builder: (context, _) {
        final stats = PlayerStatsService.instance;
        final history = stats.matchHistory;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
        // Balão de Atualização Silencioso
        if (_availableUpdate != null && !_dismissedUpdate)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ChessBalloonCard(
              type: BalloonType.coach,
              tail: BubbleTail.bottom,
              avatar: const PawnLogo(size: 26, color: AppColors.chessGreen, hasBadge: true),
              title: 'Nova Versão Disponível (${_availableUpdate!.latestVersion})',
              message: 'Uma atualização do chessD foi lançada no GitHub com novidades.',
              action: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _dismissedUpdate = true),
                    child: Text('Depois', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openUpdateUrl(_availableUpdate!.downloadUrl),
                    icon: const Icon(Icons.download, size: 16, color: Colors.white),
                    label: const Text('Baixar Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chessGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Card Panorâmico "Problemas"
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.chessGreen.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.extension, color: AppColors.chessGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Problemas', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (ffi != null) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfinitePuzzlesScreen(ffi: ffi!)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.chessGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Resolva!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${stats.puzzlesSolved} resolvidos', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.chessGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Sequência: ${stats.puzzleStreak}', style: const TextStyle(color: AppColors.chessGold, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card Problema Diário
        InkWell(
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfinitePuzzlesScreen(ffi: ffi!)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.chessGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, color: AppColors.chessGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Problema Diário', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Desafio Tático de Hoje', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.chessGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Jogar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Confronto Recomendado
        Text('Confronto Recomendado', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.chessGreen, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('O Trilheiro', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.chessGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BOT 600', style: TextStyle(color: AppColors.chessGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Casual & Amigável', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () {
                  if (ffi != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BotGameScreen(ffi: ffi!, botElo: 600, botName: 'O Trilheiro (600)')),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: AppColors.chessGreen),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Grade de Ratings (Bullet, Blitz, Rápido, Diário)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ratings', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text('Ver todos', style: TextStyle(color: AppColors.chessGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildRatingItem(icon: Icons.rocket_launch_rounded, title: 'Bullet', rating: '1200', color: AppColors.chessGold),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.bolt_rounded, title: 'Blitz', rating: '1200', color: AppColors.chessGold),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.timer_outlined, title: 'Rápido', rating: '1200', color: AppColors.chessGreen),
            const SizedBox(width: 8),
            _buildRatingItem(icon: Icons.wb_sunny_outlined, title: 'Diário', rating: '1200', color: AppColors.chessGold),
          ],
        ),

        const SizedBox(height: 20),

        // Jogar com Bots
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

        const SizedBox(height: 20),

        // Histórico de Partidas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Histórico de partidas', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
            Text('Precisão', style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.history_toggle_off, color: theme.textSecondary.withOpacity(0.6), size: 28),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma partida registrada ainda',
                  style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toque em Jogar para iniciar seu histórico e análise de precisão CAPS2.',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          ...history.take(5).map(
            (match) => InkWell(
              onTap: () {
                if (ffi != null && match.movesUci.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameReviewScreen(
                        ffi: ffi!,
                        movesPlayedUci: match.movesUci,
                        playerColor: match.playerColor,
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: _buildHistoryItem(
                opponent: match.opponent,
                isWin: match.isWin,
                isDraw: match.isDraw,
                precision: match.precision,
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            if (ffi != null) {
              final sampleMoves = history.isNotEmpty && history.first.movesUci.isNotEmpty
                  ? history.first.movesUci
                  : const ['e2e4', 'e7e5', 'g1f3', 'd7d6', 'd2d4'];
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GameReviewScreen(
                    ffi: ffi!,
                    movesPlayedUci: sampleMoves,
                    playerColor: history.isNotEmpty ? history.first.playerColor : 'white',
                  ),
                ),
              );
            }
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Revisar Última Análise', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 16),
      ],
    );
      },
    );
  }

  Widget _buildHistoryItem({
    required String opponent,
    required bool isWin,
    required bool isDraw,
    required String precision,
  }) {
    final theme = ThemeController.instance;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(opponent, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isWin
                  ? AppColors.chessGreen.withOpacity(0.2)
                  : (isDraw ? Colors.grey.withOpacity(0.2) : AppColors.moveBlunder.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isWin ? '+' : (isDraw ? '=' : '-'),
              style: TextStyle(
                color: isWin ? AppColors.chessGreen : (isDraw ? Colors.grey : AppColors.moveBlunder),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(precision, style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
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
            Icon(icon, color: color, size: 22),
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
              color: AppColors.chessGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.chessGreen, size: 22),
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
                      child: Text('$elo', style: const TextStyle(color: AppColors.chessGreen, fontWeight: FontWeight.bold, fontSize: 10)),
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
              backgroundColor: AppColors.chessGreen,
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

  // TAB 2: TRILHA DE PROBLEMAS (PROGRESSION TRACK ESTILO CHESS.COM)
  Widget _buildPuzzlesTab() {
    final theme = ThemeController.instance;
    const totalPuzzlesInTrack = 40;
    const zoneTitles = [
      'Etapa 1: Acampamento dos Mates Básicos',
      'Etapa 2: Vale dos Garfos e Cravadas',
      'Etapa 3: Planalto dos Finais Táticos',
      'Etapa 4: Fortaleza das Redes de Mate',
      'Etapa 5: Cume dos Grandes Mestres',
    ];
    const offsets = [-46.0, 0.0, 46.0, 0.0];

    return AnimatedBuilder(
      animation: PlayerStatsService.instance,
      builder: (context, _) {
        final stats = PlayerStatsService.instance;
        final currentProgress = stats.puzzleTrailNode.clamp(1, totalPuzzlesInTrack);
        final completedCount = (currentProgress - 1).clamp(0, totalPuzzlesInTrack);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Header de Progresso da Trilha
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.chessGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.extension, color: AppColors.chessGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Trilha de Problemas', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: theme.textPrimary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Elo ${stats.puzzleRating}', style: TextStyle(color: AppColors.chessGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completedCount / totalPuzzlesInTrack,
                            backgroundColor: theme.surfaceElevatedColor,
                            color: AppColors.chessGreen,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$completedCount / $totalPuzzlesInTrack', style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Caminho Senoidal Contínuo / Trilha de PedrasChanfradas
            ...List.generate(totalPuzzlesInTrack, (idx) {
              final stepNum = idx + 1;
              final isCompleted = stepNum < currentProgress;
              final isCurrent = stepNum == currentProgress;
              final isLocked = stepNum > currentProgress;
              final isZoneStart = idx % 8 == 0;
              final zoneIdx = (idx ~/ 8).clamp(0, zoneTitles.length - 1);

              final double xOffset = offsets[idx % offsets.length];
              final double prevOffset = idx > 0 ? offsets[(idx - 1) % offsets.length] : 0.0;

              return Column(
                children: [
                  if (isZoneStart)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: idx == 0 ? 4 : 24, bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLocked ? theme.borderColor : AppColors.chessGold.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLocked ? Icons.lock_outline : Icons.flag_rounded,
                            color: isLocked ? theme.textSecondary : AppColors.chessGold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              zoneTitles[zoneIdx],
                              style: TextStyle(
                                color: isLocked ? theme.textSecondary : theme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (idx > 0 && !isZoneStart)
                    TrailConnectorSegment(
                      fromOffsetX: prevOffset,
                      toOffsetX: xOffset,
                      isCompleted: isCompleted,
                      height: 30,
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Transform.translate(
                      offset: Offset(xOffset, 0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: !isLocked
                                ? () {
                                    if (ffi != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => InfinitePuzzlesScreen(
                                            ffi: ffi!,
                                            trailNode: stepNum,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: isCompleted
                                    ? AppColors.chessGold
                                    : (isCurrent ? AppColors.chessGreen : theme.surfaceElevatedColor.withOpacity(0.6)),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.white.withOpacity(0.85)
                                      : (isCompleted ? Colors.white.withOpacity(0.6) : theme.borderColor),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCurrent
                                        ? AppColors.primaryCyanDark
                                        : (isCompleted ? const Color(0xFFB58012) : Colors.black38),
                                    blurRadius: 0,
                                    offset: const Offset(0, 5),
                                  ),
                                  if (isCurrent)
                                    BoxShadow(
                                      color: AppColors.chessGreen.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                                    : (isCurrent
                                        ? Text(
                                            '$stepNum',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                                          )
                                        : Icon(Icons.lock_outline_rounded, color: theme.textSecondary.withOpacity(0.5), size: 24)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Problema $stepNum',
                            style: TextStyle(
                              color: isCurrent ? AppColors.chessGreen : (isCompleted ? theme.textPrimary : theme.textSecondary.withOpacity(0.5)),
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // TAB 3: APRENDER (TRILHA DE MAESTRIA & REPERTÓRIO)
  Widget _buildLearnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(
          title: 'Trilha de Maestria',
          subtitle: 'Lições guiadas em curva senoidal com teoria e baterias táticas passo a passo.',
          icon: Icons.alt_route,
          accentColor: AppColors.chessGreen,
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearningTrackScreen(ffi: ffi!)));
          },
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          title: 'Treinador de Repertório (SM-2)',
          subtitle: 'Memorização científica com repetição espaçada SuperMemo para linhas de abertura.',
          icon: Icons.psychology,
          accentColor: AppColors.chessGold,
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
          accentColor: AppColors.chessGreen,
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

  // TAB 5: MAIS (MENU COMPLETO OFICIAL ESTILO CHESS.COM)
  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildMenuItem(
          icon: Icons.emoji_events_outlined,
          title: 'Torneios (Sistema Suíço FIDE)',
          subtitle: 'Campeonatos com faixas de Elo (Iniciante 300-800, Amador, Mestres)',
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentManagerScreen(ffi: ffi!)));
          },
        ),
        _buildMenuItem(
          icon: Icons.tune_rounded,
          title: 'Estúdio de Criação de Bots',
          subtitle: 'Crie robôs com estilos posicional, agressivo ou defensivo',
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => BotStudioScreen(ffi: ffi!)));
          },
        ),
        _buildMenuItem(
          icon: Icons.wifi_tethering,
          title: 'Multiplayer Online P2P',
          subtitle: 'Disputa online direta via WebRTC sem custos de servidor',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnlineMultiplayerScreen()));
          },
        ),
        _buildMenuItem(
          icon: Icons.palette_outlined,
          title: 'Personalização Visual & Paletas',
          subtitle: '8 paletas de tabuleiro, 5 estilos de peças e acentos FIDE',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()));
          },
        ),
        _buildMenuItem(
          icon: Icons.people_outline,
          title: 'Pass & Play (2 Jogadores)',
          subtitle: 'Partida local no mesmo aparelho com relógio digital duplo',
          onTap: () {
            if (ffi != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PassAndPlayScreen(ffi: ffi!)));
          },
        ),
        _buildMenuItem(
          icon: Icons.casino_outlined,
          title: 'Xadrez 960 (Fischer Random)',
          subtitle: 'Sorteio aleatório de uma das 960 posições de Bobby Fischer',
          onTap: () {
            if (ffi != null) {
              final (seed, fen) = ffi!.getRandomChess960();
              final game960 = ffi!.newGameFromFen(fen);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BotGameScreen(ffi: ffi!, botName: 'Xadrez 960 (#$seed)', botElo: 1400)),
              ).then((_) => ffi!.freeGame(game960));
            }
          },
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Central de Ajuda & Regras FIDE',
          subtitle: 'Manual oficial de regras, FAQs e guia de operação',
          alwaysEnabled: true,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
          },
        ),
        _buildMenuItem(
          icon: Icons.system_update_alt,
          title: 'Verificar Atualizações',
          subtitle: _availableUpdate != null
              ? 'Nova versão ${_availableUpdate!.latestVersion} disponível!'
              : 'Versão instalada: ${AppUpdateService.currentVersion}',
          alwaysEnabled: true,
          highlightBadge: _availableUpdate?.latestVersion,
          onTap: _manualCheckForUpdate,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool alwaysEnabled = false,
    String? highlightBadge,
  }) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: highlightBadge != null ? AppColors.chessGreen : theme.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: (alwaysEnabled || isRustReady) ? onTap : null,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (highlightBadge != null ? AppColors.chessGold : AppColors.chessGreen).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: highlightBadge != null ? AppColors.chessGold : AppColors.chessGreen, size: 20),
          ),
          title: Text(title, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: highlightBadge != null ? AppColors.chessGreen : theme.textSecondary,
              fontSize: 11,
              fontWeight: highlightBadge != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: highlightBadge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chessGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    highlightBadge,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                )
              : Icon(Icons.chevron_right, color: theme.textSecondary.withOpacity(0.5), size: 20),
        ),
      ),
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
