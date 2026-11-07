import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';
import 'package:soberano_chess/ui/core/chess_theme.dart';

class CoordinateTrainerScreen extends StatefulWidget {
  final ChessTheme theme;

  const CoordinateTrainerScreen({
    super.key,
    this.theme = ChessTheme.tournamentGreen,
  });

  @override
  State<CoordinateTrainerScreen> createState() => _CoordinateTrainerScreenState();
}

class _CoordinateTrainerScreenState extends State<CoordinateTrainerScreen> {
  final Random _rng = Random();
  bool isPlaying = false;
  int timeLeft = 30;
  int score = 0;
  int highScore = 0;
  String currentTargetSquare = 'e4';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      timeLeft = 30;
      score = 0;
      _nextSquare();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 1) {
        timer.cancel();
        setState(() {
          isPlaying = false;
          timeLeft = 0;
          if (score > highScore) {
            highScore = score;
          }
        });
      } else {
        setState(() {
          timeLeft -= 1;
        });
      }
    });
  }

  void _nextSquare() {
    final file = String.fromCharCode('a'.codeUnitAt(0) + _rng.nextInt(8));
    final rank = 1 + _rng.nextInt(8);
    setState(() {
      currentTargetSquare = '$file$rank';
    });
  }

  void _onSquareTapped(String square) {
    if (!isPlaying) return;

    if (square == currentTargetSquare) {
      setState(() {
        score += 1;
      });
      _nextSquare();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Treinador de Coordenadas', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Placar e Cronômetro
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TEMPO RESTANTE', style: AppTypography.labelSmall),
                        Text('$timeLeft s', style: AppTypography.displayMedium.copyWith(color: AppColors.primaryCyan)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ACERTOS / RECORDE', style: AppTypography.labelSmall),
                        Text('$score / $highScore', style: AppTypography.displayMedium.copyWith(color: AppColors.secondaryAmber)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Alvo Atual
              if (isPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primaryCyan),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Toque na casa: ', style: AppTypography.titleMedium),
                      Text(
                        currentTargetSquare.toUpperCase(),
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primaryCyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  timeLeft == 0 ? 'Fim de Treino! Pontuação: $score' : 'Toque em Iniciar para treinar seus reflexos',
                  style: AppTypography.titleMedium,
                ),

              const SizedBox(height: 16),

              // Tabuleiro Vazio de Coordenadas
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceElevated, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Column(
                          children: List.generate(8, (rowIdx) {
                            final rank = 8 - rowIdx;
                            return Expanded(
                              child: Row(
                                children: List.generate(8, (colIdx) {
                                  final file = String.fromCharCode('a'.codeUnitAt(0) + colIdx);
                                  final square = '$file$rank';
                                  final isLight = (colIdx + rank) % 2 != 0;
                                  final color = isLight ? widget.theme.lightSquareColor : widget.theme.darkSquareColor;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => _onSquareTapped(square),
                                      child: Container(
                                        color: color,
                                        alignment: Alignment.center,
                                        child: isPlaying
                                            ? null
                                            : Text(
                                                square,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isLight ? Colors.black38 : Colors.white38,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão de Ação na Zona do Polegar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isPlaying ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isPlaying ? 'Treinando...' : 'INICIAR (30 Segundos)',
                    style: AppTypography.labelLarge.copyWith(color: Colors.black),
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
