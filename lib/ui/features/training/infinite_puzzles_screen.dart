import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/data/repositories/puzzle_repository.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/player_stats_service.dart';
import 'package:chess_d/services/user_mistakes_service.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import '../board/chess_board_widget.dart';

class InfinitePuzzlesScreen extends StatefulWidget {
  final ChessRustFfi ffi;
  final int? trailNode;

  const InfinitePuzzlesScreen({
    super.key,
    required this.ffi,
    this.trailNode,
  });

  @override
  State<InfinitePuzzlesScreen> createState() => _InfinitePuzzlesScreenState();
}

class _InfinitePuzzlesScreenState extends State<InfinitePuzzlesScreen> {
  final PuzzleRepository puzzleRepo = PuzzleRepository();
  late int playerRating;
  late int currentStreak;
  late int activeNode;
  Puzzle? currentPuzzle;
  late Pointer<Void> _game;
  bool isSolved = false;
  bool isFailed = false;
  String feedbackText = 'Encontre o melhor lance!';
  int currentMoveIdx = 0;
  String _currentPositionFen = '';

  @override
  void initState() {
    super.initState();
    PlayerStatsService.instance.loadSync();
    UserMistakesService.loadSync();
    playerRating = PlayerStatsService.instance.puzzleRating;
    currentStreak = PlayerStatsService.instance.puzzleStreak;
    activeNode = widget.trailNode ?? PlayerStatsService.instance.puzzleTrailNode;
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
    if (!mounted) return;
    setState(() {
      if (currentPuzzle != null) {
        widget.ffi.freeGame(_game);
      }
      currentPuzzle = puzzle;
      _game = widget.ffi.newGameFromFen(puzzle.fen);
      _currentPositionFen = puzzle.fen;
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

        final newRating = update['new_rating'] as int? ?? playerRating + 12;
        final newStreak = update['current_streak'] as int? ?? currentStreak + 1;
        final change = update['change'] ?? 12;

        setState(() {
          isSolved = true;
          playerRating = newRating;
          currentStreak = newStreak;
          feedbackText = 'Correto! (+$change Elo) Marco #$activeNode superado!';
        });

        PlayerStatsService.instance.recordPuzzleResult(
          solved: true,
          newRating: newRating,
          newStreak: newStreak,
          targetTrailNode: activeNode,
        );
      } else {
        // Lance intermediário do oponente
        currentMoveIdx += 1;
        final opponentUci = currentPuzzle!.movesUci[currentMoveIdx];
        widget.ffi.playUci(_game, opponentUci);
        _currentPositionFen = (widget.ffi.getStatus(_game)['fen'] as String?) ?? _currentPositionFen;
        currentMoveIdx += 1;
        setState(() {
          feedbackText = 'Bom lance! Continue a combinação...';
        });
      }
    } else {
      // Errou o lance: grava erro em UserMistakesService para treino
      final update = widget.ffi.updatePuzzleRating(
        playerRating: playerRating,
        puzzleRating: currentPuzzle!.rating,
        isSuccess: false,
        currentStreak: currentStreak,
      );

      final newRating = update['new_rating'] as int? ?? playerRating - 10;
      final change = update['change'] ?? -10;

      setState(() {
        isFailed = true;
        playerRating = newRating;
        currentStreak = 0;
        feedbackText = 'Incorreto ($change Elo). Lance esperado: $expectedUci. Erro salvo para revisão!';
      });

      PlayerStatsService.instance.recordPuzzleResult(
        solved: false,
        newRating: newRating,
        newStreak: 0,
      );

      UserMistakesService.recordMistake(
        title: 'Gafe no Problema #$activeNode (${currentPuzzle!.themes.firstOrNull ?? "Tática"})',
        fen: _currentPositionFen.isNotEmpty ? _currentPositionFen : currentPuzzle!.fen,
        blunderPlayedUci: uci,
        bestMoveUci: expectedUci,
        explanation: 'A continuação tática exigia $expectedUci. Pratique a refutação para não repetir o erro.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentPuzzle == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.chessGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.trailNode != null ? 'Trilha: Problema #${widget.trailNode}' : 'Quebra-Cabeças Infinitos',
          style: AppTypography.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppColors.chessGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Elo $playerRating',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barra de Trilha / HUD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Row(
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
                          child: const Icon(Icons.alt_route, color: AppColors.chessGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PROGRESSO NA TRILHA', style: AppTypography.labelSmall),
                            Text('Problema #$activeNode de 40', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                        const SizedBox(width: 4),
                        Text('$currentStreak', style: AppTypography.displayMedium.copyWith(color: Colors.orange, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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
                    ? const Icon(Icons.check_circle, color: AppColors.chessGreen, size: 24)
                    : isFailed
                        ? const Icon(Icons.cancel, color: AppColors.moveBlunder, size: 24)
                        : const PawnLogo(size: 22, color: AppColors.chessGreen, hasBadge: false),
                title: isSolved
                    ? 'Excelente Resolução!'
                    : isFailed
                        ? 'Tentativa Incorreta'
                        : 'Sua Vez de Jogar',
                message: feedbackText,
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 14),

              // Botão Próximo Problema
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      activeNode = (activeNode + 1).clamp(1, 40);
                    });
                    _loadNextPuzzle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSolved ? AppColors.chessGreen : AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isSolved ? Icons.arrow_forward : Icons.skip_next, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isSolved ? 'PRÓXIMO PROBLEMA DA TRILHA' : 'PULAR PROBLEMA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
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
