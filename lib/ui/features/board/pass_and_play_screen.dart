import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'chess_board_widget.dart';

class PassAndPlayScreen extends StatefulWidget {
  final ChessRustFfi ffi;
  final int initialMinutes;
  final int incrementSeconds;

  const PassAndPlayScreen({
    super.key,
    required this.ffi,
    this.initialMinutes = 5,
    this.incrementSeconds = 3,
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
    setState(() {
      isClockRunning = false;
      isGameOver = true;
      outcomeText = 'Tempo esgotado! Vitória das $winner';
    });
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
        outcomeText = 'Fim de Jogo ($outcome): $reason';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pass & Play (2 Jogadores)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(
              showHeatmap ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              color: showHeatmap ? Colors.orange : Colors.white70,
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
            // Relógio das Pretas (Invertido para o jogador do topo)
            Expanded(
              flex: 1,
              child: RotatedBox(
                quarterTurns: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentTurn == 'black' ? AppColors.surfaceElevated : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentTurn == 'black' ? AppColors.primaryCyan : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('JOGADOR PRETO', style: AppTypography.titleMedium),
                      Text(
                        _formatClock(blackTimeMillis),
                        style: AppTypography.displayLarge.copyWith(
                          color: blackTimeMillis < 10000 ? AppColors.moveBlunder : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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

            if (outcomeText != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  outcomeText!,
                  style: AppTypography.titleLarge.copyWith(color: AppColors.secondaryAmber),
                  textAlign: TextAlign.center,
                ),
              ),

            // Relógio das Brancas (Jogador de baixo)
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentTurn == 'white' ? AppColors.surfaceElevated : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentTurn == 'white' ? AppColors.primaryCyan : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('JOGADOR BRANCO', style: AppTypography.titleMedium),
                    Text(
                      _formatClock(whiteTimeMillis),
                      style: AppTypography.displayLarge.copyWith(
                        color: whiteTimeMillis < 10000 ? AppColors.moveBlunder : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
