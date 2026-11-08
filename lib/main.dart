import 'package:flutter/material.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/services/wifi_cast_server.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';
import 'package:soberano_chess/ui/core/chess_theme.dart';
import 'package:soberano_chess/ui/features/board/coordinate_trainer.dart';
import 'package:soberano_chess/ui/features/board/pass_and_play_screen.dart';
import 'package:soberano_chess/ui/features/game/bot_game_screen.dart';
import 'package:soberano_chess/ui/features/game/bot_studio_screen.dart';
import 'package:soberano_chess/ui/features/learning/learning_track_screen.dart';
import 'package:soberano_chess/ui/features/training/infinite_puzzles_screen.dart';
import 'package:soberano_chess/ui/features/training/puzzle_ladder_screen.dart';
import 'package:soberano_chess/ui/features/training/retry_mistakes_screen.dart';
import 'package:soberano_chess/ui/features/analysis/game_review_screen.dart';
import 'package:soberano_chess/ui/features/analysis/anti_cheat_audit_screen.dart';
import 'package:soberano_chess/ui/features/openings/opening_explorer_screen.dart';
import 'package:soberano_chess/ui/features/repertoire/repertoire_trainer_screen.dart';
import 'package:soberano_chess/ui/features/tournament/tournament_manager_screen.dart';
import 'package:soberano_chess/ui/features/settings/offline_packs_screen.dart';
import 'package:soberano_chess/ui/features/settings/theme_customization_screen.dart';
import 'package:soberano_chess/ui/features/multiplayer/online_multiplayer_screen.dart';
import 'package:soberano_chess/ui/features/settings/help_support_screen.dart';

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
  late final ChessRustFfi ffi;
  late final WifiCastServer castServer;
  bool isRustReady = false;
  String rustCoreStatus = 'Iniciando Rust Core...';

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
      ffi = ChessRustFfi();
      final testGame = ffi.newGame();
      final status = ffi.getStatus(testGame);
      ffi.freeGame(testGame);

      setState(() {
        isRustReady = true;
        rustCoreStatus = 'Rust Core ARM64 Ativo (${status['legal_moves']?.length ?? 0} lances)';
      });
    } catch (e) {
      setState(() {
        isRustReady = false;
        rustCoreStatus = 'Erro ao carregar Rust: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield, color: ThemeController.instance.accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'chessD',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: ThemeController.instance.accentColor),
            tooltip: 'Ajuda & Guia',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: ThemeController.instance.accentColor),
            tooltip: 'Personalização Visual',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRustReady ? AppColors.accentEmerald.withOpacity(0.15) : AppColors.moveBlunder.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isRustReady ? AppColors.accentEmerald : AppColors.moveBlunder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isRustReady ? AppColors.accentEmerald : AppColors.moveBlunder,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRustReady ? 'RUST ENGINE' : 'OFFLINE',
                      style: AppTypography.labelSmall.copyWith(
                        color: isRustReady ? AppColors.accentEmerald : AppColors.moveBlunder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          cacheExtent: 5000,
          padding: const EdgeInsets.all(16),
          children: [
            // Banner de Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF151C28), Color(0xFF1E2838)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceElevated),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.memory, color: AppColors.primaryCyan, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cérebro Nativo em Alta Performance', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(rustCoreStatus, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('APRENDIZADO & QUEBRA-CABEÇAS (FASE 4)', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 1: Trilha de Maestria Duolingo
            _buildModeCard(
              title: 'Trilha de Maestria (Estilo Duolingo)',
              subtitle: 'Navegue pelo caminho senoidal com lições guiadas, mini-aulas e baterias táticas.',
              icon: Icons.alt_route,
              accentColor: AppColors.accentEmerald,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LearningTrackScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 2: Quebra-Cabeças Infinitos
            _buildModeCard(
              title: 'Quebra-Cabeças Infinitos',
              subtitle: 'Treino ilimitado offline com calibração adaptativa de Elo e multiplicador de combo 🔥.',
              icon: Icons.extension,
              accentColor: AppColors.primaryCyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InfinitePuzzlesScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 3: Escada de Problemas (Puzzle Rush)
            _buildModeCard(
              title: 'Escada de Problemas (Rush 3 Vidas)',
              subtitle: 'Modo sobrevivência: resolva problemas de dificuldade crescente até acumular 3 erros.',
              icon: Icons.trending_up,
              accentColor: AppColors.secondaryAmber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PuzzleLadderScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('ANÁLISE & COACH IA (FASE 5)', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 4: Revisão de Partida & Coach IA
            _buildModeCard(
              title: 'Revisão de Partida & Coach IA',
              subtitle: 'Análise profunda CAPS2, gráfico de vantagem, detecção de tilt e cartões virais.',
              icon: Icons.analytics,
              accentColor: Colors.pinkAccent,
              onTap: () {
                // Demonstração com a célebre partida Opera Game de Paul Morphy
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameReviewScreen(
                      ffi: ffi,
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
              },
            ),

            const SizedBox(height: 24),
            const Text('PARTIDAS & MODOS ESPECIAIS', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 5: Batalha contra Bots
            _buildModeCard(
              title: 'Partida contra Bots',
              subtitle: 'Jogue contra bots calibrados de Elo 400 a 2200 com personalidades táticas.',
              icon: Icons.smart_toy,
              accentColor: AppColors.primaryCyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BotGameScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 6: Pass & Play (2 Jogadores)
            _buildModeCard(
              title: 'Pass & Play (2 Jogadores)',
              subtitle: 'Jogue presencialmente no mesmo celular com relógio tátil duplo espelhado.',
              icon: Icons.people_alt,
              accentColor: AppColors.secondaryAmber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PassAndPlayScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 7: Treinador de Coordenadas
            _buildModeCard(
              title: 'Treinador de Coordenadas',
              subtitle: 'Desafio de 30 segundos contra o relógio para dominar a visão de casas no tabuleiro.',
              icon: Icons.speed,
              accentColor: AppColors.accentEmerald,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CoordinateTrainerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 8: Xadrez 960 (Fischer Random)
            _buildModeCard(
              title: 'Xadrez 960 (Fischer Random)',
              subtitle: 'Sorteio aleatório de uma das 960 posições oficiais de Bobby Fischer.',
              icon: Icons.casino,
              accentColor: Colors.purpleAccent,
              onTap: () {
                final (seed, fen) = ffi.getRandomChess960();
                final game960 = ffi.newGameFromFen(fen);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BotGameScreen(
                      ffi: ffi,
                      botName: 'Xadrez 960 (Posição #$seed)',
                      botElo: 1400,
                    ),
                  ),
                ).then((_) => ffi.freeGame(game960));
              },
            ),

            const SizedBox(height: 24),
            const Text('RECURSOS DE ELITE & ABERTURAS (FASE 6)', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 9: Treinador de Repertório (SM-2)
            _buildModeCard(
              title: 'Treinador de Repertório (SM-2)',
              subtitle: 'Memorização científica com repetição espaçada SuperMemo para linhas de abertura.',
              icon: Icons.psychology,
              accentColor: AppColors.secondaryAmber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RepertoireTrainerScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 10: Explorador de Aberturas (ECO)
            _buildModeCard(
              title: 'Explorador de Aberturas (ECO)',
              subtitle: 'Catálogo profundo de linhas mestras, variantes teóricas e estatísticas de vitória.',
              icon: Icons.menu_book,
              accentColor: AppColors.primaryCyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OpeningExplorerScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 11: Treino de Erros Próprios (Retry Mistakes)
            _buildModeCard(
              title: 'Treino de Erros Próprios',
              subtitle: 'Recurso Diamante gratuito: repita seus lances errados e aprenda a refutação correta.',
              icon: Icons.replay,
              accentColor: AppColors.accentEmerald,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RetryMistakesScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 12: Estúdio de Criação de Bots
            _buildModeCard(
              title: 'Estúdio de Criação de Bots',
              subtitle: 'Crie oponentes personalizados com personalidades táticas, posicional ou clássica.',
              icon: Icons.tune,
              accentColor: Colors.deepOrangeAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BotStudioScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 13: Gerenciador de Torneios (Sistema Suíço)
            _buildModeCard(
              title: 'Torneios Locais (Sistema Suíço)',
              subtitle: 'Organize campeonatos presenciais com emparceiramento oficial FIDE e desempates.',
              icon: Icons.emoji_events,
              accentColor: Colors.amberAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TournamentManagerScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Card 14: Perícia Forense Anti-Cheat
            _buildModeCard(
              title: 'Perícia Forense Anti-Cheat',
              subtitle: 'Auditoria estatística FIDE/Regan para detecção de lances assistidos por motor.',
              icon: Icons.security,
              accentColor: AppColors.moveBlunder,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AntiCheatAuditScreen(ffi: ffi),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('CONECTIVIDADE & ACERVO EXPANDIDO (FASE 7)', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 15: Acervo Offline & Wi-Fi Cast
            _buildModeCard(
              title: 'Acervo Offline & Wi-Fi Cast',
              subtitle: 'Gerenciador de 4.2M+ puzzles Zstandard e espelhamento ao vivo para Smart TV.',
              icon: Icons.cast_connected,
              accentColor: AppColors.primaryCyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OfflinePacksScreen(castServer: castServer),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('APARÊNCIA & PERSONALIZAÇÃO VISUAL', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 16: Personalização Visual
            _buildModeCard(
              title: 'Personalização Visual & Paletas',
              subtitle: 'Alterne entre Modo Claro e Noite, escolha entre 8 paletas de tabuleiro, 5 estilos de peças e cores de acento.',
              icon: Icons.palette,
              accentColor: ThemeController.instance.accentColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeCustomizationScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('MULTIPLAYER & COMUNICAÇÃO', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 17: Multiplayer Online P2P
            _buildModeCard(
              title: 'Multiplayer Online P2P (Custo Zero)',
              subtitle: 'Jogue online via WebRTC direto com STUN do Google e fallback em Cloudflare Workers. 100% gratuito.',
              icon: Icons.wifi_tethering,
              accentColor: AppColors.primaryCyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnlineMultiplayerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('SUPORTE & APRENDIZADO', style: AppTypography.labelSmall),
            const SizedBox(height: 12),

            // Card 18: Central de Ajuda
            _buildModeCard(
              title: 'Central de Ajuda & Guia chessD',
              subtitle: 'Guia do multiplayer online, manual de regras oficiais FIDE (roque, en passant) e FAQ completo.',
              icon: Icons.help_outline,
              accentColor: AppColors.secondaryAmber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
          ],
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
    return InkWell(
      onTap: isRustReady ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeController.instance.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeController.instance.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(color: ThemeController.instance.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: ThemeController.instance.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
