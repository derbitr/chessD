import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/chess_theme.dart';
import '../board/chess_board_widget.dart';
import '../../../services/chess_rust_ffi.dart';
import '../../../services/p2p_multiplayer_service.dart';

class OnlineMultiplayerScreen extends StatefulWidget {
  const OnlineMultiplayerScreen({super.key});

  @override
  State<OnlineMultiplayerScreen> createState() => _OnlineMultiplayerScreenState();
}

class _OnlineMultiplayerScreenState extends State<OnlineMultiplayerScreen> {
  final P2PMultiplayerService _service = P2PMultiplayerService.instance;
  final ChessRustFfi _ffi = ChessRustFfi();
  late Pointer<Void> _game;
  final TextEditingController _joinCodeController = TextEditingController();

  bool _isInGame = false;
  String _currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  int _moveCount = 0;
  bool _isMyTurn = true;
  Timer? _localClockTimer;

  // Opções de criação de sala
  int _selectedMinutes = 5;
  int _selectedIncrement = 3;
  PlayerColor _selectedColor = PlayerColor.white;

  StreamSubscription? _moveSub;
  StreamSubscription? _gameEndedSub;

  @override
  void initState() {
    super.initState();
    _game = _ffi.newGame();
    _service.addListener(_onServiceUpdate);

    _moveSub = _service.onMoveReceived.listen((event) {
      if (mounted) {
        try {
          _ffi.playUci(_game, event.san);
        } catch (_) {}
        setState(() {
          _currentFen = event.fenAfter;
          _moveCount = event.moveNumber;
          _isMyTurn = true;
        });
      }
    });

    _gameEndedSub = _service.onGameEnded.listen((message) {
      if (mounted) {
        _showGameOverDialog(message);
      }
    });
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _startClockTicker() {
    _localClockTimer?.cancel();
    _localClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isInGame && mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _handleCreateRoom() async {
    final code = await _service.createRoom(
      preferredColor: _selectedColor,
      timeMinutes: _selectedMinutes,
      incrementSeconds: _selectedIncrement,
    );

    try { _ffi.freeGame(_game); } catch (_) {}
    _game = _ffi.newGame();

    setState(() {
      _isInGame = true;
      _currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      _moveCount = 0;
      _isMyTurn = (_service.assignedColor == PlayerColor.white);
    });

    _startClockTicker();
  }

  Future<void> _handleJoinRoom() async {
    final code = _joinCodeController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe um código de sala válido.')),
      );
      return;
    }

    final ok = await _service.joinRoom(code);
    if (ok) {
      try { _ffi.freeGame(_game); } catch (_) {}
      _game = _ffi.newGame();

      setState(() {
        _isInGame = true;
        _currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
        _moveCount = 0;
        _isMyTurn = (_service.assignedColor == PlayerColor.white);
      });
      _startClockTicker();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao conectar à sala. Verifique o código.')),
      );
    }
  }

  void _handleLocalUciMove(String uci) {
    if (!_isMyTurn) return;
    if (uci.length < 4) return;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promo = uci.length > 4 ? uci.substring(4, 5) : null;

    final fromIdx = _squareToIdx(from);
    final toIdx = _squareToIdx(to);

    _moveCount++;
    _service.sendMove(
      moveNumber: _moveCount,
      fromSq: fromIdx,
      toSq: toIdx,
      promotion: promo,
      san: uci,
      fenBefore: _currentFen,
    );

    setState(() {
      _isMyTurn = false;
    });
  }

  int _squareToIdx(String sq) {
    if (sq.length != 2) return 0;
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = sq.codeUnitAt(1) - '1'.codeUnitAt(0);
    return rank * 8 + file;
  }

  String _formatTime(int ms) {
    final totalSec = (ms / 1000).clamp(0, 7200).floor();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showGameOverDialog(String message) {
    _localClockTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Fim de Partida', style: AppTypography.titleLarge.copyWith(color: AppColors.primaryCyan)),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isInGame = false;
              });
              _service.disconnect();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
            child: const Text('Voltar ao Lobby', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _moveSub?.cancel();
    _gameEndedSub?.cancel();
    _localClockTimer?.cancel();
    _joinCodeController.dispose();
    try {
      _ffi.freeGame(_game);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: Text(_isInGame ? 'Partida Online P2P' : 'Multiplayer Online (Custo Zero)', style: AppTypography.titleLarge),
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        actions: [
          if (_isInGame)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _service.state == MultiplayerConnectionState.connectedP2P
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _service.state == MultiplayerConnectionState.connectedP2P ? Colors.green : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _service.state == MultiplayerConnectionState.connectedP2P ? Icons.bolt : Icons.cloud_outlined,
                        size: 14,
                        color: _service.state == MultiplayerConnectionState.connectedP2P ? Colors.greenAccent : Colors.lightBlueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_service.latencyMs} ms • ${_service.state == MultiplayerConnectionState.connectedP2P ? "P2P Direto" : "Relay Serverless"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isInGame ? _buildLiveMatchView(theme) : _buildLobbyView(theme),
    );
  }

  Widget _buildLobbyView(ThemeController theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Destaque da Arquitetura
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withOpacity(0.15),
                  AppColors.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primaryCyan, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rede P2P & Borda Serverless', style: AppTypography.titleMedium.copyWith(color: AppColors.primaryCyan)),
                      const SizedBox(height: 4),
                      Text(
                        'Conexão direta WebRTC com STUN do Google e fallback em Cloudflare Workers. 100% gratuito, sem limites de partidas.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card 1: Criar Sala
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Criar Nova Partida', style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                Text('Controle de Tempo:', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTimeControlChip('1 min (Bullet)', 1, 0),
                    _buildTimeControlChip('3 + 2s (Blitz)', 3, 2),
                    _buildTimeControlChip('5 + 3s (Rápida)', 5, 3),
                    _buildTimeControlChip('10 + 5s (Clássica)', 10, 5),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Sua Preferência de Peças:', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildColorChoiceChip('Brancas', PlayerColor.white),
                    const SizedBox(width: 8),
                    _buildColorChoiceChip('Pretas', PlayerColor.black),
                    const SizedBox(width: 8),
                    _buildColorChoiceChip('Aleatório', PlayerColor.random),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleCreateRoom,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                    label: const Text('Criar Sala & Gerar Código', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card 2: Entrar em Sala
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrar em Sala de Amigo', style: AppTypography.titleLarge),
                const SizedBox(height: 8),
                Text('Insira o código de 6 caracteres compartilhado pelo seu amigo:', style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _joinCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'EX: K9W2B4',
                          hintStyle: TextStyle(color: Colors.grey.shade600, letterSpacing: 2),
                          filled: true,
                          fillColor: theme.isDarkMode ? Colors.black26 : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleJoinRoom,
                        icon: const Icon(Icons.login),
                        label: const Text('Conectar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAmber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeControlChip(String label, int min, int inc) {
    final isSelected = (_selectedMinutes == min && _selectedIncrement == inc);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedMinutes = min;
          _selectedIncrement = inc;
        });
      },
      selectedColor: AppColors.primaryCyan.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryCyan : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildColorChoiceChip(String label, PlayerColor color) {
    final isSelected = (_selectedColor == color);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedColor = color;
        });
      },
      selectedColor: AppColors.primaryCyan.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryCyan : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLiveMatchView(ThemeController theme) {
    final code = _service.roomCode ?? '------';

    return Column(
      children: [
        // Painel do Oponente
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _service.isOpponentConnected ? Colors.green : Colors.orange,
                    child: Icon(_service.isOpponentConnected ? Icons.person : Icons.hourglass_top, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _service.isOpponentConnected ? (_service.opponentName ?? 'Adversário') : 'Aguardando adversário...',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _service.isOpponentConnected ? 'Pronto para jogar' : 'Compartilhe o código: $code',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: !_isMyTurn ? AppColors.primaryCyan.withOpacity(0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: !_isMyTurn ? AppColors.primaryCyan : Colors.transparent),
                ),
                child: Text(
                  _formatTime(_service.opponentRemainingTimeMs),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: !_isMyTurn ? AppColors.primaryCyan : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Barra de Código de Sala quando ainda aguarda
        if (!_service.isOpponentConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber.shade900.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: Text('Código da Sala: $code', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copiar Código',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Código $code copiado para a área de transferência!')),
                    );
                  },
                ),
              ],
            ),
          ),

        // Banner de Proposta de Empate
        if (_service.drawOfferedByOpponent)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade900,
            child: Row(
              children: [
                const Expanded(child: Text('O adversário propôs empate.')),
                TextButton(
                  onPressed: () => _service.respondToDraw(true),
                  child: const Text('Aceitar', style: TextStyle(color: Colors.greenAccent)),
                ),
                TextButton(
                  onPressed: () => _service.respondToDraw(false),
                  child: const Text('Recusar', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),

        // Tabuleiro Interativo
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ChessBoardWidget(
                ffi: _ffi,
                game: _game,
                isFlipped: _service.assignedColor == PlayerColor.black,
                onMovePlayed: (uci) => _handleLocalUciMove(uci),
              ),
            ),
          ),
        ),

        // Painel do Jogador Local
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryCyan,
                    child: Icon(Icons.person, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Você (chessD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        _isMyTurn ? 'SUA VEZ DE JOGAR' : 'Aguardando lance adversário...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isMyTurn ? Colors.greenAccent : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isMyTurn ? AppColors.primaryCyan.withOpacity(0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isMyTurn ? AppColors.primaryCyan : Colors.transparent),
                ),
                child: Text(
                  _formatTime(_service.myRemainingTimeMs),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isMyTurn ? AppColors.primaryCyan : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Barra de Ações (Empate / Abandono)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.surfaceElevatedColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  _service.offerDraw();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proposta de empate enviada.')),
                  );
                },
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Propor Empate'),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Abandonar Partida?'),
                      content: const Text('Você declarará vitória para o adversário.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _service.resign();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Abandonar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.redAccent),
                label: const Text('Abandonar', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
