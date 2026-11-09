import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/user_mistakes_service.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
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
  int currentIdx = 0;
  Pointer<Void>? _game;
  bool isCompleted = false;
  String feedbackText = 'Encontre o melhor lance para superar o erro!';
  Color feedbackColor = AppColors.chessGreen;

  @override
  void initState() {
    super.initState();
    _initDrillState();
  }

  void _initDrillState() {
    final list = UserMistakesService.mistakes;
    if (list.isNotEmpty) {
      if (currentIdx >= list.length) currentIdx = 0;
      _loadCurrentDrill();
    } else {
      if (_game != null) {
        widget.ffi.freeGame(_game!);
        _game = null;
      }
    }
  }

  void _loadCurrentDrill() {
    final list = UserMistakesService.mistakes;
    if (list.isEmpty) return;

    if (_game != null) {
      widget.ffi.freeGame(_game!);
    }

    final drill = list[currentIdx];
    _game = widget.ffi.newGameFromFen(drill['fen'] as String);
    isCompleted = false;
    feedbackText = 'Você jogou ${drill['blunder_played_uci']}. Encontre a refutação correta!';
    feedbackColor = AppColors.chessGreen;
  }

  @override
  void dispose() {
    if (_game != null) {
      widget.ffi.freeGame(_game!);
      _game = null;
    }
    super.dispose();
  }

  void _onMovePlayed(String uci) {
    if (isCompleted || _game == null) return;

    final list = UserMistakesService.mistakes;
    if (list.isEmpty) return;

    final drill = list[currentIdx];
    final expected = drill['best_move_uci'] as String;

    if (uci == expected) {
      setState(() {
        isCompleted = true;
        UserMistakesService.markSolved(drill['id'] as String);
        feedbackText = 'Acertou em cheio! ${drill['explanation']}';
        feedbackColor = AppColors.chessGreen;
      });
    } else {
      setState(() {
        feedbackText = 'Ainda não é o melhor lance. Tente novamente!';
        feedbackColor = AppColors.moveBlunder;
        if (_game != null) {
          widget.ffi.freeGame(_game!);
        }
        _game = widget.ffi.newGameFromFen(drill['fen'] as String);
      });
    }
  }

  void _nextDrill() {
    final list = UserMistakesService.mistakes;
    if (list.isEmpty) return;

    setState(() {
      currentIdx = (currentIdx + 1) % list.length;
      _loadCurrentDrill();
    });
  }

  void _loadDemoMistakes() {
    setState(() {
      UserMistakesService.loadSampleDrills();
      currentIdx = 0;
      _loadCurrentDrill();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = UserMistakesService.mistakes;
    final solvedCount = UserMistakesService.solvedCount;
    final totalCount = UserMistakesService.totalCount;

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ERROS SUPERADOS', style: AppTypography.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          '$solvedCount / $totalCount',
                          style: AppTypography.displayMedium.copyWith(color: AppColors.chessGold),
                        ),
                      ],
                    ),
                    if (list.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: AppColors.chessGreen),
                        tooltip: 'Próximo Erro',
                        onPressed: _nextDrill,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (list.isEmpty)
                // Estado Vazio Confiável e Honesto (Zero Erros se Nunca Jogou)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.chessGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_outlined, color: AppColors.chessGreen, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum Erro Registrado!',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você ainda não possui erros ou gafes em partidas salvas neste dispositivo. Conforme você disputar partidas contra bots, amigos ou resolver quebra-cabeças, suas gafes serão salvas automaticamente aqui para você praticar e superá-las.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _loadDemoMistakes,
                        icon: const Icon(Icons.school, size: 18, color: AppColors.chessGreen),
                        label: const Text('Carregar Exercícios de Demonstração', style: TextStyle(color: AppColors.chessGreen, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.chessGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Informação do Erro Atual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    list[currentIdx]['title'] as String? ?? 'Gafe a Corrigir',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),

                const SizedBox(height: 12),

                // Tabuleiro Interativo
                if (_game != null)
                  ChessBoardWidget(
                    ffi: widget.ffi,
                    game: _game!,
                    onMovePlayed: isCompleted ? null : _onMovePlayed,
                  ),

                const SizedBox(height: 12),

                // Balão de Feedback no Padrão Chess.com
                ChessBalloonCard(
                  type: isCompleted ? BalloonType.success : BalloonType.coach,
                  tail: BubbleTail.top,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  avatar: isCompleted
                      ? const Icon(Icons.check_circle, color: AppColors.chessGreen, size: 24)
                      : const PawnLogo(size: 22, color: AppColors.chessGold, hasBadge: false),
                  title: isCompleted ? 'Erro Superado!' : 'Treinador de Erros',
                  message: feedbackText,
                ),

                const SizedBox(height: 16),

                if (isCompleted)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _nextDrill,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: const Text('PRÓXIMO ERRO A CORRIGIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.chessGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
