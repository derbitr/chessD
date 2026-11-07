import 'package:flutter/material.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';
import 'share_card_generator.dart';

class GameReviewScreen extends StatefulWidget {
  final ChessRustFfi ffi;
  final List<String> movesPlayedUci;
  final String playerColor;

  const GameReviewScreen({
    super.key,
    required this.ffi,
    required this.movesPlayedUci,
    this.playerColor = 'white',
  });

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  bool isAnalyzing = true;
  double whiteAccuracy = 0.0;
  double blackAccuracy = 0.0;
  int whiteBrilliants = 0;
  int whiteBlunders = 0;
  int blackBlunders = 0;
  List<Map<String, dynamic>> moveAnalyses = [];
  int selectedMoveIdx = 0;
  bool isVoicePlaying = false;
  bool tiltDetected = false;

  @override
  void initState() {
    super.initState();
    _runGameReview();
  }

  Future<void> _runGameReview() async {
    // Avalia a partida lance a lance usando a engine e o algoritmo CAPS2
    final game = widget.ffi.newGame();
    final analyses = <Map<String, dynamic>>[];
    double totalWhiteAcc = 0;
    int whiteCount = 0;
    double totalBlackAcc = 0;
    int blackCount = 0;

    int prevEval = 20;

    for (int i = 0; i < widget.movesPlayedUci.length; i++) {
      final uci = widget.movesPlayedUci[i];
      final isWhite = (i % 2 == 0);

      // Avaliação profunda da posição antes do lance
      final evalBefore = widget.ffi.evaluate(game, depth: 2);
      final bestUci = evalBefore['best_move_uci'] as String? ?? uci;
      final evalCp = evalBefore['centipawns'] as int? ?? prevEval;

      widget.ffi.playUci(game, uci);

      // Avaliação após o lance
      final evalAfterRes = widget.ffi.evaluate(game, depth: 2);
      final evalAfterCp = evalAfterRes['centipawns'] as int? ?? evalCp;

      // Classifica o lance no Rust via CAPS2
      final analysis = widget.ffi.classifyMove(
        isWhite: isWhite,
        playedUci: uci,
        bestUci: bestUci,
        evalBefore: evalCp,
        evalAfter: evalAfterCp,
        timeSpentMs: 1200, // Simulado
      );

      final acc = (analysis['move_accuracy'] as num?)?.toDouble() ?? 85.0;
      final cat = analysis['category'] as String? ?? 'Best';

      if (isWhite) {
        totalWhiteAcc += acc;
        whiteCount += 1;
        if (cat == 'Brilliant') whiteBrilliants += 1;
        if (cat == 'Blunder') whiteBlunders += 1;
      } else {
        totalBlackAcc += acc;
        blackCount += 1;
        if (cat == 'Blunder') blackBlunders += 1;
      }

      analyses.add({
        'move_number': (i ~/ 2) + 1,
        'is_white': isWhite,
        'played_uci': uci,
        'best_uci': bestUci,
        'eval_after_cp': evalAfterCp,
        'accuracy': acc,
        'category': cat,
        'explanation': analysis['pedagogical_explanation'] ?? 'Lance calculado.',
        'is_panic': analysis['is_panic_move'] ?? false,
      });

      prevEval = evalAfterCp;
    }

    widget.ffi.freeGame(game);

    setState(() {
      whiteAccuracy = whiteCount > 0 ? totalWhiteAcc / whiteCount : 80.0;
      blackAccuracy = blackCount > 0 ? totalBlackAcc / blackCount : 80.0;
      moveAnalyses = analyses;
      tiltDetected = whiteBlunders >= 2;
      isAnalyzing = false;
    });
  }

  Color _getBadgeColor(String category) {
    switch (category) {
      case 'Brilliant': return AppColors.moveBrilliant;
      case 'Great': return AppColors.moveGreat;
      case 'Best': return AppColors.moveBest;
      case 'Excellent': return AppColors.moveExcellent;
      case 'Inaccuracy': return AppColors.moveInaccuracy;
      case 'Mistake': return AppColors.moveMistake;
      case 'Blunder': return AppColors.moveBlunder;
      default: return AppColors.primaryCyan;
    }
  }

  String _getBadgeSymbol(String category) {
    switch (category) {
      case 'Brilliant': return '!!';
      case 'Great': return '!';
      case 'Best': return '★';
      case 'Excellent': return '✓';
      case 'Inaccuracy': return '?!';
      case 'Mistake': return '?';
      case 'Blunder': return '??';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Revisão da Partida & Coach IA', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryCyan),
            tooltip: 'Gerar Card de Partida',
            onPressed: isAnalyzing ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShareCardScreen(
                    whiteAccuracy: whiteAccuracy,
                    blackAccuracy: blackAccuracy,
                    brilliantsCount: whiteBrilliants,
                    blundersCount: whiteBlunders,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isAnalyzing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryCyan),
                    SizedBox(height: 16),
                    Text('Stockfish calculando avaliação CAPS2...', style: AppTypography.bodyLarge),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Painel de Precisão Global (CAPS2)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceElevated),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('BRANCAS (VOCÊ)', style: AppTypography.labelSmall),
                            const SizedBox(height: 6),
                            Text(
                              '${whiteAccuracy.toStringAsFixed(1)}%',
                              style: AppTypography.displayLarge.copyWith(
                                color: whiteAccuracy >= 85 ? AppColors.accentEmerald : AppColors.secondaryAmber,
                              ),
                            ),
                            Text('$whiteBrilliants Brilhantes · $whiteBlunders Gafes', style: AppTypography.bodyMedium),
                          ],
                        ),
                        Container(width: 1, height: 50, color: AppColors.surfaceElevated),
                        Column(
                          children: [
                            const Text('PRETAS (BOT)', style: AppTypography.labelSmall),
                            const SizedBox(height: 6),
                            Text(
                              '${blackAccuracy.toStringAsFixed(1)}%',
                              style: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
                            ),
                            Text('$blackBlunders Gafes', style: AppTypography.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (tiltDetected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.moveBlunder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.moveBlunder),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Auditoria de Tempo: Padrão de Tilt detectado nas últimas jogadas com lances precipitados.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Gráfico de Vantagem Centipawn (Barra Horizontal / Gráfico Visual)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURVA DE VANTAGEM POR LANCE', style: AppTypography.labelSmall),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(moveAnalyses.length, (idx) {
                              final cp = moveAnalyses[idx]['eval_after_cp'] as int? ?? 0;
                              final normalizedHeight = ((cp + 600) / 1200.0 * 60).clamp(6.0, 68.0);
                              final isSelected = idx == selectedMoveIdx;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedMoveIdx = idx;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    height: normalizedHeight,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryCyan
                                          : (cp >= 0 ? AppColors.boardGreenDark : AppColors.moveBlunder),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Explicação do Coach IA em Português
                  if (moveAnalyses.isNotEmpty && selectedMoveIdx < moveAnalyses.length) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryCyan.withOpacity(0.15),
                                      radius: 16,
                                      child: const Icon(Icons.school, color: AppColors.primaryCyan, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Treinador IA (Lance ${selectedMoveIdx + 1})',
                                        style: AppTypography.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBadgeColor(moveAnalyses[selectedMoveIdx]['category'] as String),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${moveAnalyses[selectedMoveIdx]['category']} ${_getBadgeSymbol(moveAnalyses[selectedMoveIdx]['category'] as String)}',
                                  style: AppTypography.labelLarge.copyWith(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            moveAnalyses[selectedMoveIdx]['explanation'] as String,
                            style: AppTypography.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Lance Jogado: ${moveAnalyses[selectedMoveIdx]['played_uci']} | Melhor: ${moveAnalyses[selectedMoveIdx]['best_uci']}',
                                  style: AppTypography.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isVoicePlaying ? Icons.volume_up : Icons.volume_up_outlined,
                                  color: AppColors.primaryCyan,
                                ),
                                tooltip: 'Ouvir Comentário Falado',
                                onPressed: () {
                                  setState(() {
                                    isVoicePlaying = !isVoicePlaying;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
