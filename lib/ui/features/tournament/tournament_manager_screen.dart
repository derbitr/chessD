import 'package:flutter/material.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';

class TournamentManagerScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const TournamentManagerScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<TournamentManagerScreen> createState() => _TournamentManagerScreenState();
}

class _TournamentManagerScreenState extends State<TournamentManagerScreen> {
  final List<Map<String, dynamic>> players = [
    {'id': 'p1', 'name': 'Magnus', 'rating': 2850, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
    {'id': 'p2', 'name': 'Hikaru', 'rating': 2800, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
    {'id': 'p3', 'name': 'Alireza', 'rating': 2780, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
    {'id': 'p4', 'name': 'Gukesh', 'rating': 2760, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
    {'id': 'p5', 'name': 'Pragg', 'rating': 2750, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
    {'id': 'p6', 'name': 'Nodirbek', 'rating': 2740, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
  ];

  List<Map<String, dynamic>> currentPairings = [];
  int roundNumber = 0;
  final TextEditingController _newPlayerController = TextEditingController();

  void _generateNextRound() {
    final result = widget.ffi.generateSwissPairings(players);
    final rawPairings = result['pairings'] as List<dynamic>? ?? [];
    final updatedPlayers = result['updated_players'] as List<dynamic>? ?? [];

    setState(() {
      roundNumber += 1;
      currentPairings = rawPairings.map((p) => Map<String, dynamic>.from(p as Map)).toList();
      if (updatedPlayers.isNotEmpty) {
        for (int i = 0; i < players.length && i < updatedPlayers.length; i++) {
          players[i] = Map<String, dynamic>.from(updatedPlayers[i] as Map);
        }
      }
    });
  }

  void _recordResult(int pairingIdx, String result) {
    final pairing = currentPairings[pairingIdx];
    pairing['result'] = result;

    final wId = pairing['white_player_id'] as String;
    final bId = pairing['black_player_id'] as String;

    final wPlayer = players.firstWhere((p) => p['id'] == wId);
    final bPlayer = players.firstWhere((p) => p['id'] == bId);

    setState(() {
      if (result == '1-0') {
        wPlayer['score'] = (wPlayer['score'] as num) + 1.0;
      } else if (result == '0-1') {
        bPlayer['score'] = (bPlayer['score'] as num) + 1.0;
      } else if (result == '1/2-1/2') {
        wPlayer['score'] = (wPlayer['score'] as num) + 0.5;
        bPlayer['score'] = (bPlayer['score'] as num) + 0.5;
      }

      (wPlayer['opponents_played'] as List).add(bId);
      (bPlayer['opponents_played'] as List).add(wId);
      (wPlayer['color_history'] as List).add('W');
      (bPlayer['color_history'] as List).add('B');
    });
  }

  String _getPlayerName(String id) {
    final p = players.firstWhere((pl) => pl['id'] == id, orElse: () => {'name': id});
    return p['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    // Ordena classificação por pontos
    final sortedStandings = List<Map<String, dynamic>>.from(players)
      ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Torneios (Sistema Suíço FIDE)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled, color: AppColors.primaryCyan),
            tooltip: 'Gerar Próxima Rodada',
            onPressed: _generateNextRound,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Painel de Rodada e Ações
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceElevated),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roundNumber == 0 ? 'TORNEIO PRONTO' : 'RODADA $roundNumber',
                          style: AppTypography.titleLarge.copyWith(color: AppColors.secondaryAmber),
                        ),
                        const SizedBox(height: 4),
                        Text('${players.length} Mestres Inscritos', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _generateNextRound,
                    icon: const Icon(Icons.shuffle, color: Colors.black, size: 18),
                    label: Text(
                      roundNumber == 0 ? 'EMPARCEIRAR' : 'NOVA RODADA',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Emparceiramentos da Rodada
            if (currentPairings.isNotEmpty) ...[
              Text('EMPARCEIRAMENTOS - RODADA $roundNumber', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              ...List.generate(currentPairings.length, (idx) {
                final pair = currentPairings[idx];
                final whiteName = _getPlayerName(pair['white_player_id'] as String);
                final blackName = _getPlayerName(pair['black_player_id'] as String);
                final res = pair['result'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(whiteName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(res ?? 'vs', style: const TextStyle(color: AppColors.secondaryAmber, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Text(blackName, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                        onSelected: (val) => _recordResult(idx, val),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: '1-0', child: Text('1-0 (Vitória Brancas)')),
                          const PopupMenuItem(value: '1/2-1/2', child: Text('½-½ (Empate)')),
                          const PopupMenuItem(value: '0-1', child: Text('0-1 (Vitória Pretas)')),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Tabela de Classificação
            const Text('CLASSIFICAÇÃO GERAL', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceElevated),
              ),
              child: Column(
                children: List.generate(sortedStandings.length, (idx) {
                  final p = sortedStandings[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: idx < sortedStandings.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.surfaceElevated))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('${idx + 1}º', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryCyan)),
                        ),
                        Expanded(
                          child: Text(p['name'] as String, style: AppTypography.titleMedium),
                        ),
                        Text('Elo ${p['rating']}', style: AppTypography.bodySmall),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${p['score']} pts',
                            style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
