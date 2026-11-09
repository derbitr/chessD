import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import 'chess_board_widget.dart';

class PassAndPlayScreen extends StatefulWidget {
  final ChessRustFfi ffi;
  final int initialMinutes;
  final int incrementSeconds;
  final String? whitePlayerName;
  final String? blackPlayerName;
  final Function(String result)? onGameConcluded;

  const PassAndPlayScreen({
    super.key,
    required this.ffi,
    this.initialMinutes = 5,
    this.incrementSeconds = 3,
    this.whitePlayerName,
    this.blackPlayerName,
    this.onGameConcluded,
  });

  @override
  State<PassAndPlayScreen> createState() => _PassAndPlayScreenState();
}

class _PassAndPlayScreenState extends State<PassAndPlayScreen> {
  late Pointer<Void> _game;
  late int whiteTimeMillis;
  late int blackTimeMillis;
  Timer? _clockTimer;
  bool isClockRunning = false;
  String currentTurn = 'white';
  bool isGameOver = false;
  String? outcomeText;
  String? finalResult;
  bool showHeatmap = false;

  @override
  void initState() {
    super.initState();
    _game = widget.ffi.newGame();
    whiteTimeMillis = widget.initialMinutes * 60 * 1000;
    blackTimeMillis = widget.initialMinutes * 60 * 1000;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    widget.ffi.freeGame(_game);
    super.dispose();
  }

  void _startClock() {
    if (isClockRunning || isGameOver) return;
    isClockRunning = true;
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (currentTurn == 'white') {
          whiteTimeMillis = (whiteTimeMillis - 100).clamp(0, 99999999);
          if (whiteTimeMillis == 0) {
            _onTimeout('Pretas');
          }
        } else {
          blackTimeMillis = (blackTimeMillis - 100).clamp(0, 99999999);
          if (blackTimeMillis == 0) {
            _onTimeout('Brancas');
          }
        }
      });
    });
  }

  void _onTimeout(String winner) {
    _clockTimer?.cancel();
    final res = winner == 'Brancas' ? '1-0' : '0-1';
    setState(() {
      isClockRunning = false;
      isGameOver = true;
      finalResult = res;
      outcomeText = 'Tempo esgotado! Vitória das $winner ($res)';
    });
    widget.onGameConcluded?.call(res);
  }

  void _onMovePlayed(String uci) {
    if (!isClockRunning && !isGameOver) {
      _startClock();
    }

    final status = widget.ffi.getStatus(_game);
    setState(() {
      // Adiciona incremento
      if (currentTurn == 'white') {
        whiteTimeMillis += widget.incrementSeconds * 1000;
      } else {
        blackTimeMillis += widget.incrementSeconds * 1000;
      }

      currentTurn = status['turn'] as String? ?? 'white';
      if (status['is_game_over'] == true) {
        isGameOver = true;
        _clockTimer?.cancel();
        isClockRunning = false;
        final reason = status['termination_reason'] ?? '';
        final outcome = status['outcome'] ?? '';
        String res = '1/2-1/2';
        if (outcome == 'WhiteWins') {
          res = '1-0';
        } else if (outcome == 'BlackWins') {
          res = '0-1';
        }
        finalResult = res;
        outcomeText = 'Fim de Jogo ($res): $reason';
        widget.onGameConcluded?.call(res);
      }
    });
  }

  String _formatClock(int millis) {
    final totalSeconds = (millis / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance;
        final wName = widget.whitePlayerName ?? 'JOGADOR BRANCO';
        final bName = widget.blackPlayerName ?? 'JOGADOR PRETO';

        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: AppBar(
            title: Text(
              widget.whitePlayerName != null
                  ? '$wName vs $bName'
                  : 'Pass & Play (2 Jogadores)',
              style: AppTypography.titleLarge.copyWith(color: theme.textPrimary),
            ),
            backgroundColor: theme.surfaceColor,
            iconTheme: IconThemeData(color: theme.textPrimary),
            actions: [
              IconButton(
                icon: Icon(
                  showHeatmap ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                  color: showHeatmap ? Colors.orange : theme.textSecondary,
                ),
                tooltip: 'Alternar Mapa de Calor',
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
                // Painel Padronizado das Pretas (Invertido para o jogador oposto)
                RotatedBox(
                  quarterTurns: 2,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: currentTurn == 'black' ? theme.surfaceElevatedColor : theme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentTurn == 'black' ? theme.accentColor : theme.borderColor,
                        width: 1.5,
                      ),
                      boxShadow: currentTurn == 'black'
                          ? [
                              BoxShadow(
                                color: theme.accentColor.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: PawnLogo(size: 22, color: Color(0xFF1E293B), hasBadge: false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  bName.toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentTurn == 'black' ? 'Vez de Jogar' : 'Aguardando',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: currentTurn == 'black' ? theme.accentColor : theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: blackTimeMillis < 10000 ? AppColors.moveBlunder : Colors.white12,
                            ),
                          ),
                          child: Text(
                            _formatClock(blackTimeMillis),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: blackTimeMillis < 10000 ? AppColors.moveBlunder : theme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Tabuleiro Central
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ChessBoardWidget(
                    ffi: widget.ffi,
                    game: _game,
                    showHeatmap: showHeatmap,
                    onMovePlayed: _onMovePlayed,
                  ),
                ),

                const SizedBox(height: 4),

                if (outcomeText != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ChessBalloonCard(
                      type: BalloonType.success,
                      tail: BubbleTail.bottom,
                      avatar: const Icon(Icons.emoji_events, color: AppColors.secondaryAmber, size: 24),
                      title: 'Fim de Jogo',
                      message: outcomeText!,
                      action: finalResult != null
                          ? SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(finalResult),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                                label: Text(
                                  'Salvar Resultado ($finalResult)',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: theme.accentColor),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],

                // Painel Padronizado das Brancas (Jogador inferior)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: currentTurn == 'white' ? theme.surfaceElevatedColor : theme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: currentTurn == 'white' ? theme.accentColor : theme.borderColor,
                      width: 1.5,
                    ),
                    boxShadow: currentTurn == 'white'
                        ? [
                            BoxShadow(
                              color: theme.accentColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const Center(
                              child: PawnLogo(size: 22, color: Colors.white, hasBadge: false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                wName.toUpperCase(),
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currentTurn == 'white' ? 'Vez de Jogar' : 'Aguardando',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: currentTurn == 'white' ? theme.accentColor : theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: whiteTimeMillis < 10000 ? AppColors.moveBlunder : Colors.white12,
                          ),
                        ),
                        child: Text(
                          _formatClock(whiteTimeMillis),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: whiteTimeMillis < 10000 ? AppColors.moveBlunder : theme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
