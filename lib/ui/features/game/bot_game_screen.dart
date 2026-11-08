import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import '../board/chess_board_widget.dart';
import '../analysis/game_review_screen.dart';

class BotGameScreen extends StatefulWidget {
  final ChessRustFfi ffi;
  final int botElo;
  final int botPersonality; // 0 = classical, 1 = aggressive, 2 = positional
  final String botName;

  const BotGameScreen({
    super.key,
    required this.ffi,
    this.botElo = 1200,
    this.botPersonality = 1,
    this.botName = 'Valkyrie (Agressiva)',
  });

  @override
  State<BotGameScreen> createState() => _BotGameScreenState();
}

class _BotGameScreenState extends State<BotGameScreen> {
  late Pointer<Void> _game;
  bool isBotThinking = false;
  bool showHeatmap = false;
  String? gameOutcome;
  List<String> moveHistory = [];

  @override
  void initState() {
    super.initState();
    _game = widget.ffi.newGame();
  }

  @override
  void dispose() {
    widget.ffi.freeGame(_game);
    super.dispose();
  }

  void _onPlayerMove(String uci) {
    setState(() {
      moveHistory.add(uci);
    });

    final status = widget.ffi.getStatus(_game);
    if (status['is_game_over'] == true) {
      setState(() {
        gameOutcome = 'Fim de Jogo: ${status['outcome']} (${status['termination_reason']})';
      });
      return;
    }

    // Lance do Bot
    _triggerBotMove();
  }

  void _triggerBotMove() {
    setState(() {
      isBotThinking = true;
    });

    // Simula atraso humanizado de reflexão (500 a 1200 ms)
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      final botMove = widget.ffi.getBotMove(
        _game,
        elo: widget.botElo,
        personality: widget.botPersonality,
      );

      if (botMove != null && botMove['uci'] != null) {
        final uci = botMove['uci'] as String;
        widget.ffi.playUci(_game, uci);
        setState(() {
          moveHistory.add(uci);
          isBotThinking = false;
        });

        final status = widget.ffi.getStatus(_game);
        if (status['is_game_over'] == true) {
          setState(() {
            gameOutcome = 'Fim de Jogo: ${status['outcome']} (${status['termination_reason']})';
          });
        }
      } else {
        setState(() {
          isBotThinking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.botName, style: AppTypography.titleLarge),
            Text('Elo ${widget.botElo}', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryCyan)),
          ],
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(
              showHeatmap ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              color: showHeatmap ? Colors.orange : Colors.white70,
            ),
            tooltip: 'Alternar Mapa de Calor Tático',
            onPressed: () {
              setState(() {
                showHeatmap = !showHeatmap;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header do Adversário (Bot) no Padrão Chess.com
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.smart_toy, color: AppColors.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BOT',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.botName,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.botElo}',
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBotThinking ? 'Analisando variantes...' : 'Aguardando lance',
                              style: TextStyle(
                                fontSize: 11,
                                color: isBotThinking ? AppColors.secondaryAmber : AppColors.textSecondary,
                                fontStyle: isBotThinking ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isBotThinking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryCyan),
                    )
                  else
                    const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tabuleiro Interativo Padronizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ChessBoardWidget(
                ffi: widget.ffi,
                game: _game,
                showHeatmap: showHeatmap,
                onMovePlayed: isBotThinking ? null : _onPlayerMove,
              ),
            ),

            const SizedBox(height: 8),

            // Header do Jogador Humano (Você) no Padrão Chess.com
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondaryAmber.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: PawnLogo(size: 24, color: AppColors.secondaryAmber, hasBadge: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAmber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VOCÊ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Jogador',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '1500',
                                style: TextStyle(
                                  color: AppColors.secondaryAmber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              !isBotThinking && gameOutcome == null ? 'Sua vez de jogar' : 'Esperando oponente',
                              style: TextStyle(
                                fontSize: 11,
                                color: !isBotThinking && gameOutcome == null ? AppColors.accentEmerald : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isBotThinking && gameOutcome == null)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),

            if (gameOutcome != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: ChessBalloonCard(
                  type: BalloonType.hint,
                  tail: BubbleTail.top,
                  avatar: const Icon(Icons.emoji_events, color: AppColors.secondaryAmber, size: 28),
                  title: 'Fim de Jogo',
                  message: gameOutcome!,
                  action: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameReviewScreen(
                              ffi: widget.ffi,
                              movesPlayedUci: moveHistory,
                              playerColor: 'white',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics, color: Colors.black),
                      label: const Text(
                        'REVISAR PARTIDA COM COACH IA',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Histórico Rápido de Lances
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: moveHistory.isEmpty
                  ? const Center(
                      child: Text('Nenhum lance jogado ainda', style: AppTypography.bodyMedium),
                    )
                  : ListView.builder(
                      itemCount: (moveHistory.length / 2).ceil(),
                      itemBuilder: (context, idx) {
                        final whiteMove = moveHistory[idx * 2];
                        final blackMove = (idx * 2 + 1 < moveHistory.length) ? moveHistory[idx * 2 + 1] : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              SizedBox(width: 32, child: Text('${idx + 1}.', style: AppTypography.labelSmall)),
                              Expanded(child: Text(whiteMove, style: AppTypography.bodyMedium.copyWith(color: Colors.white))),
                              Expanded(child: Text(blackMove, style: AppTypography.bodyMedium)),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
