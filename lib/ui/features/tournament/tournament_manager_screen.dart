import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_theme.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import '../board/pass_and_play_screen.dart';
import '../game/bot_game_screen.dart';
import '../multiplayer/online_multiplayer_screen.dart';

enum TournamentTier {
  iniciante(
    id: 'iniciante',
    name: 'Iniciante (Elo 300 - 800)',
    description: 'Bots casuais calibrados para quem está aprendendo.',
  ),
  amador(
    id: 'amador',
    name: 'Amador / Clube (Elo 900 - 1400)',
    description: 'Jogadores de clube com boa visão tática.',
  ),
  intermediario(
    id: 'intermediario',
    name: 'Intermediário (Elo 1500 - 1900)',
    description: 'Oponentes fortes com repertório teórico sólido.',
  ),
  mestres(
    id: 'mestres',
    name: 'Mestres FIDE (Elo 2000 - 2400)',
    description: 'Cálculo profundo e estratégia posicional afiada.',
  ),
  personalizado(
    id: 'personalizado',
    name: 'Personalizado',
    description: 'Crie seu próprio torneio inscrevendo amigos.',
  );

  final String id;
  final String name;
  final String description;

  const TournamentTier({
    required this.id,
    required this.name,
    required this.description,
  });
}

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
  TournamentTier currentTier = TournamentTier.iniciante;
  late List<Map<String, dynamic>> players;
  List<Map<String, dynamic>> currentPairings = [];
  int roundNumber = 0;

  @override
  void initState() {
    super.initState();
    players = _getPlayersForTier(TournamentTier.iniciante);
  }

  List<Map<String, dynamic>> _getPlayersForTier(TournamentTier tier) {
    switch (tier) {
      case TournamentTier.iniciante:
        return [
          {'id': 'p_you', 'name': 'Você', 'rating': 500, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_ornito', 'name': 'O Ornitólogo', 'rating': 300, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_trilha', 'name': 'O Trilheiro', 'rating': 600, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_ganso', 'name': 'Ganso Tático', 'rating': 450, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_novato', 'name': 'Iniciante Local', 'rating': 550, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_amador', 'name': 'Robô Amador', 'rating': 700, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
        ];
      case TournamentTier.amador:
        return [
          {'id': 'p_you', 'name': 'Você', 'rating': 1200, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_estrateg', 'name': 'Estrategista', 'rating': 1100, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_valk', 'name': 'Valkyrie', 'rating': 1200, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_caro', 'name': 'Guarda Caro-Kann', 'rating': 1250, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_frances', 'name': 'Atacante Francês', 'rating': 1050, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_guerreiro', 'name': 'Guerreiro E4', 'rating': 1300, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
        ];
      case TournamentTier.intermediario:
        return [
          {'id': 'p_you', 'name': 'Você', 'rating': 1600, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_brutal', 'name': 'Tático Brutal', 'rating': 1550, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_capi', 'name': 'Capivara Assassina', 'rating': 1650, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_posic', 'name': 'Mestre Posicional', 'rating': 1750, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_linha', 'name': 'Linha Principal', 'rating': 1800, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_cego', 'name': 'Calculador Cego', 'rating': 1700, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
        ];
      case TournamentTier.mestres:
        return [
          {'id': 'p_you', 'name': 'Você', 'rating': 2100, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_mf', 'name': 'Mestre FIDE', 'rating': 2200, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_mi', 'name': 'Mestre Internacional', 'rating': 2300, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_gm', 'name': 'Grande Mestre', 'rating': 2400, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_deep', 'name': 'Deep Chess Jr', 'rating': 2350, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'b_stock', 'name': 'Motor Local', 'rating': 2450, 'is_bot': true, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
        ];
      case TournamentTier.personalizado:
        return [
          {'id': 'p_you', 'name': 'Você', 'rating': 1200, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
          {'id': 'p_amigo1', 'name': 'Amigo 1', 'rating': 1200, 'is_bot': false, 'score': 0.0, 'buchholz': 0.0, 'sonneborn_berger': 0.0, 'opponents_played': <String>[], 'color_history': <String>[], 'had_bye': false},
        ];
    }
  }

  void _switchTier(TournamentTier tier) {
    if (roundNumber > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeController.instance.surfaceColor,
          title: Text('Mudar Categoria de Torneio', style: TextStyle(color: ThemeController.instance.textPrimary)),
          content: Text(
            'Um torneio já está em andamento. Mudar a categoria irá reiniciar os pontos e emparceirar a nova faixa de Elo.',
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
                setState(() {
                  currentTier = tier;
                  roundNumber = 0;
                  currentPairings.clear();
                  players = _getPlayersForTier(tier);
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeController.instance.accentColor),
              child: const Text('Trocar Categoria', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        currentTier = tier;
        players = _getPlayersForTier(tier);
      });
    }
  }

  void _generateNextRound() {
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscreva pelo menos 2 competidores para iniciar o torneio.')),
      );
      return;
    }

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

  bool _isPlayerBot(Map<String, dynamic>? player) {
    if (player == null) return false;
    return player['is_bot'] == true || (player['id'] as String? ?? '').startsWith('b_');
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
          final old = players[i];
          final upd = Map<String, dynamic>.from(updatedPlayers[i] as Map);
          upd['is_bot'] = old['is_bot'] ?? (old['id'] as String? ?? '').startsWith('b_');
          players[i] = upd;
        }
      }
    });

    _recalculateTiebreaks();
  }

  void _recordResult(int pairingIdx, String result) {
    if (pairingIdx < 0 || pairingIdx >= currentPairings.length) return;
    final pairing = currentPairings[pairingIdx];
    final previousResult = pairing['result'] as String?;

    final wId = pairing['white_player_id'] as String;
    final bId = pairing['black_player_id'] as String;

    final wPlayer = players.firstWhere((p) => p['id'] == wId, orElse: () => players.first);
    final bPlayer = players.firstWhere((p) => p['id'] == bId, orElse: () => players.last);

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
    final ratingController = TextEditingController(text: '800');

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = ThemeController.instance;
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          title: Text('Adicionar Competidor', style: TextStyle(color: theme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome do Jogador ou Bot',
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
                final rating = int.tryParse(ratingController.text) ?? 800;
                if (name.isNotEmpty) {
                  setState(() {
                    players.add({
                      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                      'name': name,
                      'rating': rating,
                      'is_bot': name.toLowerCase().contains('bot') || name.toLowerCase().contains('robô'),
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
                players = _getPlayersForTier(currentTier);
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

  Map<String, dynamic>? _getPlayer(String id) {
    try {
      return players.firstWhere((pl) => pl['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _playBotMatch(int idx) async {
    final pair = currentPairings[idx];
    final wId = pair['white_player_id'] as String;
    final bId = pair['black_player_id'] as String;
    final wPlayer = _getPlayer(wId);
    final bPlayer = _getPlayer(bId);

    final botPlayer = _isPlayerBot(wPlayer) ? wPlayer! : (bPlayer ?? {'name': 'Bot', 'rating': 600});
    final userIsWhite = !_isPlayerBot(wPlayer);

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BotGameScreen(
          ffi: widget.ffi,
          botElo: (botPlayer['rating'] as num?)?.toInt() ?? 600,
          botName: botPlayer['name'] as String? ?? 'Bot',
          playerIsWhite: userIsWhite,
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
            'Qual foi o desfecho da partida entre $whiteName e $blackName?',
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

  void _showMatchOptionsDialog(int idx) {
    final pair = currentPairings[idx];
    final whiteName = _getPlayerName(pair['white_player_id'] as String);
    final blackName = _getPlayerName(pair['black_player_id'] as String);
    final wPlayer = _getPlayer(pair['white_player_id'] as String);
    final bPlayer = _getPlayer(pair['black_player_id'] as String);
    final hasBot = _isPlayerBot(wPlayer) || _isPlayerBot(bPlayer);

    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeController.instance.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = ThemeController.instance;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$whiteName vs $blackName',
                  style: AppTypography.titleLarge.copyWith(color: theme.textPrimary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha como deseja disputar esta partida:',
                  style: AppTypography.bodySmall.copyWith(color: theme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (hasBot)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _playBotMatch(idx);
                      },
                      icon: const Icon(Icons.smart_toy, color: Colors.black),
                      label: const Text('JOGAR CONTRA O BOT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _playLocalMatch(idx);
                  },
                  icon: const Icon(Icons.grid_on, color: Colors.black),
                  label: const Text('TABULEIRO LOCAL (PASS & PLAY)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _playMultiplayerMatch(idx);
                  },
                  icon: const Icon(Icons.wifi, color: AppColors.secondaryAmber),
                  label: const Text('ONLINE P2P MULTIPLAYER', style: TextStyle(color: AppColors.secondaryAmber, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondaryAmber),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _recordResult(idx, '1-0');
                        },
                        child: const Text('1-0'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _recordResult(idx, '1/2-1/2');
                        },
                        child: const Text('½-½'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _recordResult(idx, '0-1');
                        },
                        child: const Text('0-1'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            title: Row(
              children: [
                const PawnLogo(size: 24, color: AppColors.secondaryAmber, hasBadge: true),
                const SizedBox(width: 10),
                Text(
                  'Torneios Suíços',
                  style: AppTypography.titleLarge.copyWith(color: theme.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
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
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seletor de Categoria de Elo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CATEGORIA DE ELO', style: AppTypography.labelSmall.copyWith(color: theme.textSecondary)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TournamentTier.values.map((tier) {
                          final isSelected = tier == currentTier;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                tier.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : theme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: theme.accentColor,
                              backgroundColor: theme.surfaceColor,
                              onSelected: (_) => _switchTier(tier),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Painel da Rodada e Botão de Emparceirar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                              style: AppTypography.titleLarge.copyWith(color: AppColors.secondaryAmber, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${players.length} Jogadores • ${currentTier.name}',
                              style: AppTypography.bodySmall.copyWith(color: theme.textSecondary),
                              overflow: TextOverflow.ellipsis,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                        'Toque no card para opções completas',
                        style: AppTypography.bodySmall.copyWith(color: theme.accentColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(currentPairings.length, (idx) {
                    final pair = currentPairings[idx];
                    final whiteName = _getPlayerName(pair['white_player_id'] as String);
                    final blackName = _getPlayerName(pair['black_player_id'] as String);
                    final wPlayer = _getPlayer(pair['white_player_id'] as String);
                    final bPlayer = _getPlayer(pair['black_player_id'] as String);
                    final res = pair['result'] as String?;
                    final isBotMatch = _isPlayerBot(wPlayer) || _isPlayerBot(bPlayer);

                    return InkWell(
                      onTap: () => _showMatchOptionsDialog(idx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: res != null ? theme.borderColor : theme.accentColor.withOpacity(0.5),
                            width: res != null ? 1 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.black26),
                                        ),
                                        child: const Center(
                                          child: Text('♙', style: TextStyle(fontSize: 16, color: Colors.black87)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              whiteName,
                                              style: TextStyle(
                                                color: theme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${wPlayer?['rating'] ?? 800} Elo',
                                              style: TextStyle(color: theme.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Placar Central
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceElevatedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: res != null ? AppColors.accentEmerald : AppColors.secondaryAmber,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    res ?? 'vs',
                                    style: TextStyle(
                                      color: res != null ? AppColors.accentEmerald : AppColors.secondaryAmber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                // Jogador Pretas
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              blackName,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: theme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${bPlayer?['rating'] ?? 800} Elo',
                                              style: TextStyle(color: theme.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF262421),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white30),
                                        ),
                                        child: const Center(
                                          child: Text('♟', style: TextStyle(fontSize: 16, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Barra de Ações: Jogar contra Bot, Tabuleiro Local, Online P2P ou Menu Rápido
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (isBotMatch)
                                  ElevatedButton.icon(
                                    onPressed: () => _playBotMatch(idx),
                                    icon: const Icon(Icons.smart_toy, size: 15, color: Colors.black),
                                    label: const Text('Jogar contra Bot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentEmerald,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),

                                TextButton.icon(
                                  onPressed: () => _playLocalMatch(idx),
                                  icon: Icon(Icons.grid_on, size: 15, color: theme.accentColor),
                                  label: Text('Tabuleiro Local', style: TextStyle(color: theme.accentColor, fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    backgroundColor: theme.accentColor.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: () => _playMultiplayerMatch(idx),
                                  icon: const Icon(Icons.wifi, size: 15, color: AppColors.secondaryAmber),
                                  label: const Text('Online P2P', style: TextStyle(color: AppColors.secondaryAmber, fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    backgroundColor: AppColors.secondaryAmber.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: Icon(Icons.edit_note, color: theme.textSecondary, size: 22),
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
                    Text('FIDE: Pontos • Buchholz', style: AppTypography.bodySmall.copyWith(color: theme.textSecondary, fontSize: 11)),
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
                      final isBot = p['is_bot'] == true;

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
                                  Row(
                                    children: [
                                      if (isBot) ...[
                                        const Icon(Icons.smart_toy, size: 14, color: AppColors.primaryCyan),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          p['name'] as String,
                                          style: AppTypography.titleMedium.copyWith(
                                            color: theme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${p['rating']} Elo • ${isBot ? 'Bot' : 'Humano'}',
                                    style: AppTypography.bodySmall.copyWith(color: theme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(p['score'] as num).toStringAsFixed(1)} pts',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: theme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Buch: ${buch.toStringAsFixed(1)}',
                                  style: AppTypography.bodySmall.copyWith(color: theme.textSecondary, fontSize: 11),
                                ),
                              ],
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
