import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import '../board/chess_board_widget.dart';

class RepertoireTrainerScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const RepertoireTrainerScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<RepertoireTrainerScreen> createState() => _RepertoireTrainerScreenState();
}

class _RepertoireTrainerScreenState extends State<RepertoireTrainerScreen> {
  late List<Map<String, dynamic>> repertoireCards;
  int activeIndex = 0;
  late Pointer<Void> _game;
  bool isCardAnswered = false;
  String feedbackText = 'Encontre o lance do seu repertório teórico!';
  Color feedbackColor = AppColors.primaryCyan;

  @override
  void initState() {
    super.initState();
    repertoireCards = [
      {
        'id': 'rep_ita_1',
        'opening_name': 'Abertura Italiana (Giuoco Piano)',
        'fen': 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
        'expected_move_uci': 'c2c3',
        'repetition': 0,
        'interval_days': 1,
        'ease_factor': 2.5,
        'next_review_epoch': 0,
        'hint': 'Prepara o avanço central d4 com controle total do espaço.',
      },
      {
        'id': 'rep_sic_1',
        'opening_name': 'Defesa Siciliana (Variante Najdorf)',
        'fen': 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
        'expected_move_uci': 'g1f3',
        'repetition': 1,
        'interval_days': 1,
        'ease_factor': 2.5,
        'next_review_epoch': 0,
        'hint': 'Desenvolvimento clássico de cavalo preparando d4 rápido.',
      },
      {
        'id': 'rep_qgd_1',
        'opening_name': 'Gambito da Dama Recusado',
        'fen': 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
        'expected_move_uci': 'e7e6',
        'repetition': 2,
        'interval_days': 6,
        'ease_factor': 2.5,
        'next_review_epoch': 0,
        'hint': 'Sustenta o peão central d5 e preserva estrutura sólida.',
      },
    ];

    _initCardGame();
  }

  void _initCardGame() {
    final currentCard = repertoireCards[activeIndex];
    _game = widget.ffi.newGameFromFen(currentCard['fen'] as String);
    isCardAnswered = false;
    feedbackText = 'Sua vez: jogue a linha de ${currentCard['opening_name']}';
    feedbackColor = AppColors.primaryCyan;
  }

  @override
  void dispose() {
    widget.ffi.freeGame(_game);
    super.dispose();
  }

  void _onMovePlayed(String uci) {
    if (isCardAnswered) return;

    final currentCard = repertoireCards[activeIndex];
    final expected = currentCard['expected_move_uci'] as String;

    if (uci == expected) {
      setState(() {
        isCardAnswered = true;
        feedbackText = 'Excelente! Lance correto do repertório.';
        feedbackColor = AppColors.accentEmerald;
      });
    } else {
      setState(() {
        isCardAnswered = true;
        feedbackText = 'Lance fora do repertório. O lance ideal era $expected.';
        feedbackColor = AppColors.moveBlunder;
      });
    }
  }

  void _rateReview(int quality) {
    final currentEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final updated = widget.ffi.reviewSrsCard(repertoireCards[activeIndex], quality, currentEpoch);

    setState(() {
      repertoireCards[activeIndex] = {
        ...repertoireCards[activeIndex],
        ...updated,
      };

      // Avança para o próximo cartão
      widget.ffi.freeGame(_game);
      activeIndex = (activeIndex + 1) % repertoireCards.length;
      _initCardGame();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agendado para revisão em ${updated['interval_days'] ?? 1} dias (SM-2)'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = repertoireCards[activeIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Treinador de Repertório (SM-2)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Informativo do Repertório
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card['opening_name'] as String,
                            style: AppTypography.titleMedium.copyWith(color: AppColors.secondaryAmber),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EF: ${(card['ease_factor'] as num).toStringAsFixed(2)}',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primaryCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Intervalo: ${card['interval_days']} dias · Repetição: ${card['repetition']}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tabuleiro Interativo
              ChessBoardWidget(
                ffi: widget.ffi,
                game: _game,
                onMovePlayed: isCardAnswered ? null : _onMovePlayed,
              ),

              const SizedBox(height: 12),

              // Feedback Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: feedbackColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: feedbackColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCardAnswered
                          ? (feedbackColor == AppColors.accentEmerald ? Icons.check_circle : Icons.error)
                          : Icons.lightbulb_outline,
                      color: feedbackColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feedbackText,
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botoes de Avaliacao SuperMemo SM-2
              if (isCardAnswered) ...[
                const Text(
                  'AVALIAÇÃO DE MEMORIZAÇÃO (SUPERMEMO SM-2)',
                  style: AppTypography.labelSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moveBlunder,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _rateReview(1),
                        child: const Text('Errei (1d)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moveMistake,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _rateReview(3),
                        child: const Text('Difícil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyanDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _rateReview(4),
                        child: const Text('Bom', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentEmerald,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _rateReview(5),
                        child: const Text('Fácil', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
