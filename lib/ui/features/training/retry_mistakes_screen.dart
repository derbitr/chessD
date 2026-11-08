import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import '../board/chess_board_widget.dart';

class RetryMistakesScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const RetryMistakesScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<RetryMistakesScreen> createState() => _RetryMistakesScreenState();
}

class _RetryMistakesScreenState extends State<RetryMistakesScreen> {
  final List<Map<String, dynamic>> mistakeDrills = [
    {
      'id': 'mistake_1',
      'title': 'Gafe: Peça Pendurada na Abertura',
      'fen': 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 2 3',
      'blunder_played_uci': 'd2d3',
      'best_move_uci': 'd1h5',
      'explanation': 'Você jogou passivo com d3. O golpe ativo era Dh5 com ameaça de mate em f7!',
      'is_solved': false,
    },
    {
      'id': 'mistake_2',
      'title': 'Erro: Mate de Corredor Desperdiçado',
      'fen': '6k1/5ppp/8/8/8/8/1R3PPP/2R3K1 w - - 0 1',
      'blunder_played_uci': 'b2b3',
      'best_move_uci': 'c1c8',
      'explanation': 'A oitava fila estava totalmente vulnerável. Tc8# aplicava xeque-mate imediato.',
      'is_solved': false,
    },
    {
      'id': 'mistake_3',
      'title': 'Imprecisão: Garfo de Cavalo Perdido',
      'fen': 'r1b1k2r/pppp1ppp/8/2b1n3/3PP3/2N5/PPP2PPP/R1B1KB1R w KQkq - 0 1',
      'blunder_played_uci': 'f1e2',
      'best_move_uci': 'd4e5',
      'explanation': 'Capturar o cavalo em e5 com dxe5 ganha uma peça inteira.',
      'is_solved': false,
    },
  ];

  int currentIdx = 0;
  late Pointer<Void> _game;
  bool isCompleted = false;
  String feedbackText = 'Encontre o lance que você deixou passar na partida!';
  Color feedbackColor = AppColors.primaryCyan;

  @override
  void initState() {
    super.initState();
    _loadCurrentDrill();
  }

  void _loadCurrentDrill() {
    final drill = mistakeDrills[currentIdx];
    _game = widget.ffi.newGameFromFen(drill['fen'] as String);
    isCompleted = false;
    feedbackText = 'Você jogou ${drill['blunder_played_uci']}. Encontre o lance correto!';
    feedbackColor = AppColors.primaryCyan;
  }

  @override
  void dispose() {
    widget.ffi.freeGame(_game);
    super.dispose();
  }

  void _onMovePlayed(String uci) {
    if (isCompleted) return;

    final drill = mistakeDrills[currentIdx];
    final expected = drill['best_move_uci'] as String;

    if (uci == expected) {
      setState(() {
        isCompleted = true;
        drill['is_solved'] = true;
        feedbackText = 'Acertou em cheio! ${drill['explanation']}';
        feedbackColor = AppColors.accentEmerald;
      });
    } else {
      setState(() {
        feedbackText = 'Ainda não é o melhor lance. Tente novamente!';
        feedbackColor = AppColors.moveBlunder;
      });
    }
  }

  void _nextDrill() {
    widget.ffi.freeGame(_game);
    setState(() {
      currentIdx = (currentIdx + 1) % mistakeDrills.length;
      _loadCurrentDrill();
    });
  }

  @override
  Widget build(BuildContext context) {
    final drill = mistakeDrills[currentIdx];
    final solvedCount = mistakeDrills.where((d) => d['is_solved'] == true).count();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Treino de Erros Próprios', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progresso de Erros Superados
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ERROS SUPERADOS', style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            Text(
                              '$solvedCount / ${mistakeDrills.length}',
                              style: AppTypography.displayMedium.copyWith(color: AppColors.secondaryAmber),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: AppColors.primaryCyan),
                          tooltip: 'Próximo Erro',
                          onPressed: _nextDrill,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text(
                      drill['title'] as String,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primaryCyan),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tabuleiro
              ChessBoardWidget(
                ffi: widget.ffi,
                game: _game,
                onMovePlayed: isCompleted ? null : _onMovePlayed,
              ),

              const SizedBox(height: 12),

              // Feedback do Treinador
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: feedbackColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: feedbackColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.replay,
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

              if (isCompleted)
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _nextDrill,
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    label: const Text('PRÓXIMO ERRO A CORRIGIR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _IterableCount<T> on Iterable<T> {
  int count() => length;
}
