import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import '../board/pass_and_play_screen.dart';
import '../multiplayer/online_multiplayer_screen.dart';

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

  void _generateNextRound() {
    // Verifica se ainda há partidas pendentes na rodada atual
    final hasPending = currentPairings.any((p) => p['result'] == null);
    if (roundNumber > 0 && hasPending) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeController.instance.surfaceColor,
          title: Text('Partidas Pendentes', style: TextStyle(color: ThemeController.instance.textPrimary)),
          content: Text(
            'Ainda existem confrontos não finalizados na Rodada $roundNumber. Deseja forçar o emparceiramento da próxima rodada?',
            style: TextStyle(color: ThemeController.instance.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _executeGenerateNextRound();
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeController.instance.accentColor),
              child: const Text('Avançar Mesmo Assim', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    _executeGenerateNextRound();
  }

  void _executeGenerateNextRound() {
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

    _recalculateTiebreaks();
  }

  void _recordResult(int pairingIdx, String result) {
    if (pairingIdx < 0 || pairingIdx >= currentPairings.length) return;
    final pairing = currentPairings[pairingIdx];

    // Se já havia resultado prévio, subtrai a pontuação antiga antes de somar a nova
    final previousResult = pairing['result'] as String?;

    final wId = pairing['white_player_id'] as String;
    final bId = pairing['black_player_id'] as String;

    final wPlayer = players.firstWhere((p) => p['id'] == wId);
    final bPlayer = players.firstWhere((p) => p['id'] == bId);

    setState(() {
      if (previousResult != null) {
        if (previousResult == '1-0') {
          wPlayer['score'] = ((wPlayer['score'] as num) - 1.0).clamp(0.0, 999.0);
        } else if (previousResult == '0-1') {
          bPlayer['score'] = ((bPlayer['score'] as num) - 1.0).clamp(0.0, 999.0);
        } else if (previousResult == '1/2-1/2') {
          wPlayer['score'] = ((wPlayer['score'] as num) - 0.5).clamp(0.0, 999.0);
          bPlayer['score'] = ((bPlayer['score'] as num) - 0.5).clamp(0.0, 999.0);
        }
      }

      pairing['result'] = result;

      if (result == '1-0') {
        wPlayer['score'] = (wPlayer['score'] as num) + 1.0;
      } else if (result == '0-1') {
        bPlayer['score'] = (bPlayer['score'] as num) + 1.0;
      } else if (result == '1/2-1/2') {
        wPlayer['score'] = (wPlayer['score'] as num) + 0.5;
        bPlayer['score'] = (bPlayer['score'] as num) + 0.5;
      }

      final wOpponents = wPlayer['opponents_played'] as List;
      final bOpponents = bPlayer['opponents_played'] as List;
      if (!wOpponents.contains(bId)) wOpponents.add(bId);
      if (!bOpponents.contains(wId)) bOpponents.add(wId);

      final wColors = wPlayer['color_history'] as List;
      final bColors = bPlayer['color_history'] as List;
      if (wColors.length < roundNumber) wColors.add('W');
      if (bColors.length < roundNumber) bColors.add('B');
    });

    _recalculateTiebreaks();
  }

  void _recalculateTiebreaks() {
    try {
      final updated = widget.ffi.calculateTiebreaks(players);
      if (updated.isNotEmpty && mounted) {
        setState(() {
          for (int i = 0; i < players.length && i < updated.length; i++) {
            players[i]['buchholz'] = updated[i]['buchholz'] ?? players[i]['buchholz'];
            players[i]['sonneborn_berger'] = updated[i]['sonneborn_berger'] ?? players[i]['sonneborn_berger'];
          }
        });
      }
    } catch (_) {}
  }

  void _addPlayerDialog() {
    final nameController = TextEditingController();
    final ratingController = TextEditingController(text: '1500');

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = ThemeController.instance;
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          title: Text('Adicionar Jogador ao Torneio', style: TextStyle(color: theme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome do Competidor',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Rating Elo Inicial',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final rating = int.tryParse(ratingController.text) ?? 1500;
                if (name.isNotEmpty) {
                  setState(() {
                    players.add({
                      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                      'name': name,
                      'rating': rating,
                      'score': 0.0,
                      'buchholz': 0.0,
                      'sonneborn_berger': 0.0,
                      'opponents_played': <String>[],
                      'color_history': <String>[],
                      'had_bye': false,
                    });
                  });
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentColor),
              child: const Text('Inscrever', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetTournamentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeController.instance.surfaceColor,
        title: Text('Reiniciar Torneio', style: TextStyle(color: ThemeController.instance.textPrimary)),
        content: Text(
          'Deseja zerar os resultados, pontuações e histórico de rodadas deste torneio?',
          style: TextStyle(color: ThemeController.instance.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                roundNumber = 0;
                currentPairings.clear();
                for (final p in players) {
                  p['score'] = 0.0;
                  p['buchholz'] = 0.0;
                  p['sonneborn_berger'] = 0.0;
                  p['opponents_played'] = <String>[];
                  p['color_history'] = <String>[];
                  p['had_bye'] = false;
                }
              });
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.moveBlunder),
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getPlayerName(String id) {
    final p = players.firstWhere((pl) => pl['id'] == id, orElse: () => {'name': id});
    return p['name'] as String;
  }

  Future<void> _playLocalMatch(int idx) async {
    final pair = currentPairings[idx];
    final whiteName = _getPlayerName(pair['white_player_id'] as String);
    final blackName = _getPlayerName(pair['black_player_id'] as String);

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PassAndPlayScreen(
          ffi: widget.ffi,
          whitePlayerName: whiteName,
          blackPlayerName: blackName,
          onGameConcluded: (res) {
            _recordResult(idx, res);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      _recordResult(idx, result);
    }
  }

  Future<void> _playMultiplayerMatch(int idx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnlineMultiplayerScreen(),
      ),
    );

    if (!mounted) return;

    // Oferece registro rápido do resultado após retorno do modo multiplayer
    final pair = currentPairings[idx];
    final whiteName = _getPlayerName(pair['white_player_id'] as String);
    final blackName = _getPlayerName(pair['black_player_id'] as String);

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = ThemeController.instance;
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          title: Text('Concluir Partida Online', style: TextStyle(color: theme.textPrimary)),
          content: Text(
            'Qual foi o desfecho da partida entre $whiteName (Brancas) e $blackName (Pretas)?',
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Manter Pendente'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _recordResult(idx, '1-0');
              },
              child: const Text('1-0 (Brancas)'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _recordResult(idx, '1/2-1/2');
              },
              child: const Text('½-½ (Empate)'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _recordResult(idx, '0-1');
              },
              child: const Text('0-1 (Pretas)'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance;

        // Ordena classificação: 1º Pontos desc, 2º Buchholz desc, 3º Rating desc (Padrão FIDE)
        final sortedStandings = List<Map<String, dynamic>>.from(players)
          ..sort((a, b) {
            final scoreComp = (b['score'] as num).compareTo(a['score'] as num);
            if (scoreComp != 0) return scoreComp;
            final buchComp = (b['buchholz'] as num).compareTo(a['buchholz'] as num);
            if (buchComp != 0) return buchComp;
            return (b['rating'] as num).compareTo(a['rating'] as num);
          });

        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: AppBar(
            title: Text(
              'Torneios (Sistema Suíço FIDE)',
              style: AppTypography.titleLarge.copyWith(color: theme.textPrimary),
            ),
            backgroundColor: theme.surfaceColor,
            iconTheme: IconThemeData(color: theme.textPrimary),
            actions: [
              IconButton(
                icon: Icon(Icons.person_add, color: theme.accentColor),
                tooltip: 'Inscrever Jogador',
                onPressed: _addPlayerDialog,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                tooltip: 'Reiniciar Torneio',
                onPressed: _resetTournamentDialog,
              ),
              IconButton(
                icon: Icon(Icons.play_circle_filled, color: theme.accentColor),
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
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
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
                            Text(
                              '${players.length} Mestres Inscritos • Sistema Suíço Oficial',
                              style: AppTypography.bodySmall.copyWith(color: theme.textSecondary),
                            ),
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
                        style: ElevatedButton.styleFrom(backgroundColor: theme.accentColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Emparceiramentos da Rodada Atual
                if (currentPairings.isNotEmpty) ...[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'EMPARCEIRAMENTOS - RODADA $roundNumber',
                        style: AppTypography.labelSmall.copyWith(color: theme.textSecondary),
                      ),
                      Text(
                        'Toque para jogar no tabuleiro ou online',
                        style: AppTypography.bodySmall.copyWith(color: theme.accentColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(currentPairings.length, (idx) {
                    final pair = currentPairings[idx];
                    final whiteName = _getPlayerName(pair['white_player_id'] as String);
                    final blackName = _getPlayerName(pair['black_player_id'] as String);
                    final res = pair['result'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: res != null ? theme.borderColor : theme.accentColor.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Jogador Brancas
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        whiteName,
                                        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Placar / Resultado
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.surfaceElevatedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: res != null ? AppColors.accentEmerald : AppColors.secondaryAmber,
                                  ),
                                ),
                                child: Text(
                                  res ?? 'vs',
                                  style: TextStyle(
                                    color: res != null ? AppColors.accentEmerald : AppColors.secondaryAmber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Jogador Pretas
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        blackName,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Barra de Ações: Jogar Tabuleiro, Jogar Online P2P ou Menu Rápido
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Botão Tabuleiro Local (Pass & Play)
                              TextButton.icon(
                                onPressed: () => _playLocalMatch(idx),
                                icon: Icon(Icons.grid_on, size: 16, color: theme.accentColor),
                                label: Text('Tabuleiro Local', style: TextStyle(color: theme.accentColor, fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Botão Online P2P Multiplayer
                              TextButton.icon(
                                onPressed: () => _playMultiplayerMatch(idx),
                                icon: const Icon(Icons.wifi, size: 16, color: AppColors.secondaryAmber),
                                label: const Text('Online P2P', style: TextStyle(color: AppColors.secondaryAmber, fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Menu Rápido Manual
                              PopupMenuButton<String>(
                                icon: Icon(Icons.edit_note, color: theme.textSecondary, size: 20),
                                tooltip: 'Registrar Placar Manualmente',
                                onSelected: (val) => _recordResult(idx, val),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: '1-0', child: Text('1-0 (Vitória Brancas)')),
                                  const PopupMenuItem(value: '1/2-1/2', child: Text('½-½ (Empate)')),
                                  const PopupMenuItem(value: '0-1', child: Text('0-1 (Vitória Pretas)')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Tabela de Classificação Geral (FIDE com Pontos e Buchholz)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('CLASSIFICAÇÃO GERAL', style: AppTypography.labelSmall.copyWith(color: theme.textSecondary)),
                    Text('Critério: Pontos • Buchholz', style: AppTypography.bodySmall.copyWith(color: theme.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    children: List.generate(sortedStandings.length, (idx) {
                      final p = sortedStandings[idx];
                      final buch = (p['buchholz'] as num?)?.toDouble() ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: idx < sortedStandings.length - 1
                              ? Border(bottom: BorderSide(color: theme.borderColor))
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${idx + 1}º',
                                style: AppTypography.titleMedium.copyWith(
                                  color: idx == 0
                                      ? AppColors.secondaryAmber
                                      : (idx == 1 ? Colors.grey.shade400 : (idx == 2 ? const Color(0xFFCD7F32) : theme.textSecondary)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] as String,
                                    style: AppTypography.titleMedium.copyWith(color: theme.textPrimary),
                                  ),
                                  Text(
                                    'Elo ${p['rating']} • Buch: ${buch.toStringAsFixed(1)}',
                                    style: AppTypography.bodySmall.copyWith(color: theme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${p['score']} pts',
                                style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold),
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
      },
    );
  }
}
