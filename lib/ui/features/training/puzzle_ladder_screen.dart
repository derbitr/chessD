import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:soberano_chess/data/repositories/puzzle_repository.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';
import '../board/chess_board_widget.dart';

class PuzzleLadderScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const PuzzleLadderScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<PuzzleLadderScreen> createState() => _PuzzleLadderScreenState();
}

class _PuzzleLadderScreenState extends State<PuzzleLadderScreen> {
  final PuzzleRepository puzzleRepo = PuzzleRepository();
  List<Puzzle> ladderSequence = [];
  int currentIdx = 0;
  int strikes = 0;
  final int maxStrikes = 3;
  int score = 0;
  int highScore = 0;
  int streak = 0;
  bool isGameOver = false;
  late Pointer<Void> _game;
  int currentMoveIdx = 0;
  String feedbackText = 'Escada iniciada! Começando em problemas de aquecimento.';

  @override
  void initState() {
    super.initState();
    _startNewLadder();
  }

  @override
  void dispose() {
    if (ladderSequence.isNotEmpty) {
      widget.ffi.freeGame(_game);
    }
    super.dispose();
  }

  Future<void> _startNewLadder() async {
    final sequence = await puzzleRepo.getLadderSequence();
    setState(() {
      if (ladderSequence.isNotEmpty) {
        widget.ffi.freeGame(_game);
      }
      ladderSequence = sequence;
      currentIdx = 0;
      strikes = 0;
      score = 0;
      streak = 0;
      isGameOver = false;
      currentMoveIdx = 0;
      _game = widget.ffi.newGameFromFen(sequence[0].fen);
      feedbackText = 'Problema 1 (Elo ${sequence[0].rating})';
    });
  }

  void _onMovePlayed(String uci) {
    if (isGameOver || currentIdx >= ladderSequence.length) return;

    final puzzle = ladderSequence[currentIdx];
    final expectedUci = puzzle.movesUci[currentMoveIdx];

    if (uci == expectedUci) {
      if (currentMoveIdx + 1 >= puzzle.movesUci.length) {
        // Problema superado!
        score += 1;
        streak += 1;
        if (score > highScore) {
          highScore = score;
        }

        if (currentIdx + 1 < ladderSequence.length) {
          setState(() {
            currentIdx += 1;
            currentMoveIdx = 0;
            widget.ffi.freeGame(_game);
            final nextP = ladderSequence[currentIdx];
            _game = widget.ffi.newGameFromFen(nextP.fen);
            feedbackText = 'Acertou! Problema ${currentIdx + 1} (Elo ${nextP.rating}) 🔥 Streak $streak';
          });
        } else {
          // Zerou a sequência!
          setState(() {
            isGameOver = true;
            feedbackText = 'LENDÁRIO! Você completou toda a Escada de Problemas!';
          });
        }
      } else {
        currentMoveIdx += 1;
        final opponentUci = puzzle.movesUci[currentMoveIdx];
        widget.ffi.playUci(_game, opponentUci);
        currentMoveIdx += 1;
      }
    } else {
      // Errou!
      strikes += 1;
      streak = 0;

      if (strikes >= maxStrikes) {
        setState(() {
          isGameOver = true;
          feedbackText = 'Fim de Jogo! Pontuação final: $score acertos.';
        });
      } else {
        if (currentIdx + 1 < ladderSequence.length) {
          setState(() {
            currentIdx += 1;
            currentMoveIdx = 0;
            widget.ffi.freeGame(_game);
            final nextP = ladderSequence[currentIdx];
            _game = widget.ffi.newGameFromFen(nextP.fen);
            feedbackText = 'Erro! Restam ${maxStrikes - strikes} vidas. Próximo problema (${nextP.rating} Elo)';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ladderSequence.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escada de Problemas (Puzzle Rush)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barra de Status com Vidas (Corações) e Pontuação
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VIDAS RESTANTES', style: AppTypography.labelSmall),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(maxStrikes, (i) {
                            final isAlive = i < (maxStrikes - strikes);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(
                                isAlive ? Icons.favorite : Icons.favorite_border,
                                color: isAlive ? AppColors.moveBlunder : AppColors.textMuted,
                                size: 24,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ACERTOS / RECORDE', style: AppTypography.labelSmall),
                        Text('$score / $highScore', style: AppTypography.displayMedium.copyWith(color: AppColors.secondaryAmber)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Feedback Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isGameOver ? AppColors.moveBlunder.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGameOver ? AppColors.moveBlunder : AppColors.surfaceElevated,
                  ),
                ),
                child: Text(
                  feedbackText,
                  style: AppTypography.titleMedium.copyWith(
                    color: isGameOver ? AppColors.moveBlunder : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 14),

              // Tabuleiro Interativo
              Expanded(
                child: Center(
                  child: ChessBoardWidget(
                    ffi: widget.ffi,
                    game: _game,
                    onMovePlayed: isGameOver ? null : _onMovePlayed,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Botão Reiniciar se Game Over
              if (isGameOver)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startNewLadder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('RECOMEÇAR ESCADA', style: AppTypography.labelLarge),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
