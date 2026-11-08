import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import '../board/chess_board_widget.dart';

class OpeningExplorerScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const OpeningExplorerScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<OpeningExplorerScreen> createState() => _OpeningExplorerScreenState();
}

class _OpeningExplorerScreenState extends State<OpeningExplorerScreen> {
  late List<dynamic> openings;
  int selectedOpeningIdx = 0;
  late Pointer<Void> _game;

  @override
  void initState() {
    super.initState();
    openings = widget.ffi.getOpeningsCatalog();
    if (openings.isEmpty) {
      // Fallback de contingência caso FFI retorne vazio
      openings = [
        {
          'eco': 'C50',
          'name': 'Abertura Italiana (Giuoco Piano)',
          'moves_san': ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5'],
          'initial_fen': 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
          'candidate_moves': [
            {'uci': 'c2c3', 'san': 'c3', 'white_win_pct': 38.0, 'draw_pct': 36.0, 'black_win_pct': 26.0, 'popularity_games': 125000},
            {'uci': 'd2d3', 'san': 'd3', 'white_win_pct': 36.0, 'draw_pct': 42.0, 'black_win_pct': 22.0, 'popularity_games': 98000},
          ],
          'strategic_summary': 'Visão harmônica com pressão na casa f7.',
        }
      ];
    }

    _loadSelectedOpening();
  }

  void _loadSelectedOpening() {
    final current = openings[selectedOpeningIdx] as Map<String, dynamic>;
    final fen = current['initial_fen'] as String;
    _game = widget.ffi.newGameFromFen(fen);
  }

  @override
  void dispose() {
    widget.ffi.freeGame(_game);
    super.dispose();
  }

  void _selectOpening(int idx) {
    if (idx == selectedOpeningIdx) return;
    widget.ffi.freeGame(_game);
    setState(() {
      selectedOpeningIdx = idx;
      _loadSelectedOpening();
    });
  }

  void _onCandidateMoveTapped(String uci) {
    widget.ffi.playUci(_game, uci);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = openings[selectedOpeningIdx] as Map<String, dynamic>;
    final candidateMoves = (current['candidate_moves'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explorador de Aberturas (ECO)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seletor Horizontal de Aberturas
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: openings.length,
                  itemBuilder: (context, idx) {
                    final op = openings[idx] as Map<String, dynamic>;
                    final isSelected = idx == selectedOpeningIdx;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${op['eco']} - ${op['name']}'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryCyan,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _selectOpening(idx),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Tabuleiro Interativo
              ChessBoardWidget(
                ffi: widget.ffi,
                game: _game,
              ),

              const SizedBox(height: 12),

              // Resumo Estratégico
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(current['eco'] as String, style: AppTypography.labelSmall.copyWith(color: AppColors.primaryCyan)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            current['name'] as String,
                            style: AppTypography.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current['strategic_summary'] as String? ?? 'Sem notas estratégicas.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Text('LANCES MESTRES & ESTATÍSTICAS DE VITÓRIA', style: AppTypography.labelSmall),
              const SizedBox(height: 8),

              // Lista de lances candidatos com barras de proporção
              ...candidateMoves.map((cand) {
                final c = cand as Map<String, dynamic>;
                final san = c['san'] as String;
                final uci = c['uci'] as String;
                final wWin = (c['white_win_pct'] as num).toDouble();
                final draw = (c['draw_pct'] as num).toDouble();
                final bWin = (c['black_win_pct'] as num).toDouble();
                final games = c['popularity_games'] ?? 0;

                return InkWell(
                  onTap: () => _onCandidateMoveTapped(uci),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceElevated),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(san, style: AppTypography.titleMedium.copyWith(color: AppColors.secondaryAmber)),
                                const SizedBox(width: 8),
                                Text('($uci)', style: AppTypography.bodySmall),
                              ],
                            ),
                            Text('$games partidas', style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Barra tri-colorida (Brancas, Empate, Pretas)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (wWin * 10).toInt(),
                                  child: Container(color: Colors.white, alignment: Alignment.center),
                                ),
                                Expanded(
                                  flex: (draw * 10).toInt(),
                                  child: Container(color: Colors.grey.shade600),
                                ),
                                Expanded(
                                  flex: (bWin * 10).toInt(),
                                  child: Container(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Brancas ${wWin.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                            Text('Empate ${draw.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: Colors.grey)),
                            Text('Pretas ${bWin.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
