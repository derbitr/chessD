import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
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
            // Status do Bot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceElevated,
                    child: const Icon(Icons.smart_toy, color: AppColors.primaryCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.botName, style: AppTypography.titleMedium),
                        Text(
                          isBotThinking ? 'Analisando variantes...' : 'Aguardando seu lance',
                          style: TextStyle(
                            fontSize: 12,
                            color: isBotThinking ? AppColors.secondaryAmber : AppColors.textSecondary,
                            fontStyle: isBotThinking ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBotThinking)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tabuleiro Interativo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ChessBoardWidget(
                ffi: widget.ffi,
                game: _game,
                showHeatmap: showHeatmap,
                onMovePlayed: isBotThinking ? null : _onPlayerMove,
              ),
            ),

            if (gameOutcome != null) ...[
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondaryAmber),
                ),
                child: Column(
                  children: [
                    Text(
                      gameOutcome!,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.secondaryAmber),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
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
                      label: const Text('REVISAR PARTIDA COM COACH IA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

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
