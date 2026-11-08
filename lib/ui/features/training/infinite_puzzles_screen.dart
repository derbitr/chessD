import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/data/repositories/puzzle_repository.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import '../board/chess_board_widget.dart';

class InfinitePuzzlesScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const InfinitePuzzlesScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<InfinitePuzzlesScreen> createState() => _InfinitePuzzlesScreenState();
}

class _InfinitePuzzlesScreenState extends State<InfinitePuzzlesScreen> {
  final PuzzleRepository puzzleRepo = PuzzleRepository();
  int playerRating = 1200;
  int currentStreak = 0;
  Puzzle? currentPuzzle;
  late Pointer<Void> _game;
  bool isSolved = false;
  bool isFailed = false;
  String feedbackText = 'Encontre o melhor lance!';
  int currentMoveIdx = 0;

  @override
  void initState() {
    super.initState();
    _loadNextPuzzle();
  }

  @override
  void dispose() {
    if (currentPuzzle != null) {
      widget.ffi.freeGame(_game);
    }
    super.dispose();
  }

  Future<void> _loadNextPuzzle() async {
    final puzzle = await puzzleRepo.getAdaptivePuzzle(playerRating);
    setState(() {
      if (currentPuzzle != null) {
        widget.ffi.freeGame(_game);
      }
      currentPuzzle = puzzle;
      _game = widget.ffi.newGameFromFen(puzzle.fen);
      isSolved = false;
      isFailed = false;
      currentMoveIdx = 0;
      feedbackText = 'Sua vez de jogar! (${puzzle.themes.join(', ')})';
    });
  }

  void _onMovePlayed(String uci) {
    if (isSolved || isFailed || currentPuzzle == null) return;

    final expectedUci = currentPuzzle!.movesUci[currentMoveIdx];
    if (uci == expectedUci) {
      // Acertou o lance!
      if (currentMoveIdx + 1 >= currentPuzzle!.movesUci.length) {
        // Problema totalmente resolvido!
        final update = widget.ffi.updatePuzzleRating(
          playerRating: playerRating,
          puzzleRating: currentPuzzle!.rating,
          isSuccess: true,
          currentStreak: currentStreak,
        );

        setState(() {
          isSolved = true;
          playerRating = update['new_rating'] as int? ?? playerRating + 12;
          currentStreak = update['current_streak'] as int? ?? currentStreak + 1;
          final change = update['change'] ?? 12;
          feedbackText = 'Correto! (+$change Elo) 🔥 Combo $currentStreak';
        });
      } else {
        // Lance intermediário do oponente
        currentMoveIdx += 1;
        final opponentUci = currentPuzzle!.movesUci[currentMoveIdx];
        widget.ffi.playUci(_game, opponentUci);
        currentMoveIdx += 1;
        setState(() {
          feedbackText = 'Bom lance! Continue a combinação...';
        });
      }
    } else {
      // Errou o lance
      final update = widget.ffi.updatePuzzleRating(
        playerRating: playerRating,
        puzzleRating: currentPuzzle!.rating,
        isSuccess: false,
        currentStreak: currentStreak,
      );

      setState(() {
        isFailed = true;
        playerRating = update['new_rating'] as int? ?? playerRating - 10;
        currentStreak = 0;
        final change = update['change'] ?? -10;
        feedbackText = 'Incorreto ($change Elo). Tente novamente no próximo!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentPuzzle == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quebra-Cabeças Infinitos', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Painel de Rating & Streak
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
                        const Text('SEU RATING TÁTICO', style: AppTypography.labelSmall),
                        Text('$playerRating Elo', style: AppTypography.displayMedium.copyWith(color: AppColors.primaryCyan)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                        const SizedBox(width: 4),
                        Text('$currentStreak', style: AppTypography.displayMedium.copyWith(color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Balão de Feedback no Padrão Chess.com
              ChessBalloonCard(
                type: isSolved
                    ? BalloonType.success
                    : isFailed
                        ? BalloonType.error
                        : BalloonType.neutral,
                tail: BubbleTail.bottom,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                avatar: isSolved
                    ? const Icon(Icons.check_circle, color: AppColors.accentEmerald, size: 24)
                    : isFailed
                        ? const Icon(Icons.cancel, color: AppColors.moveBlunder, size: 24)
                        : const PawnLogo(size: 22, color: AppColors.primaryCyan, hasBadge: false),
                title: isSolved
                    ? 'Excelente Resolução!'
                    : isFailed
                        ? 'Tentativa Incorreta'
                        : 'Sua Vez de Jogar',
                message: feedbackText,
              ),

              const SizedBox(height: 16),

              // Tabuleiro Interativo
              Expanded(
                child: Center(
                  child: ChessBoardWidget(
                    ffi: widget.ffi,
                    game: _game,
                    onMovePlayed: _onMovePlayed,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Próximo Problema
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loadNextPuzzle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSolved ? AppColors.accentEmerald : AppColors.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isSolved ? 'PRÓXIMO PROBLEMA ➔' : 'PULAR PROBLEMA',
                    style: AppTypography.labelLarge.copyWith(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
