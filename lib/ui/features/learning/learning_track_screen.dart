import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/data/models/lesson_module.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/services/player_stats_service.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import 'package:chess_d/ui/core/trail_connector.dart';
import '../board/chess_board_widget.dart';

class LearningTrackScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const LearningTrackScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<LearningTrackScreen> createState() => _LearningTrackScreenState();
}

class _LearningTrackScreenState extends State<LearningTrackScreen> {
  final List<LessonModule> modules = LessonModule.getCuratedCurriculum();

  @override
  void initState() {
    super.initState();
    PlayerStatsService.instance.loadSync();
  }

  void _openLesson(LessonStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LessonBottomSheet(
        ffi: widget.ffi,
        step: step,
        onCompleted: (stars) {
          PlayerStatsService.instance.recordLessonCompletion(step.id, stars);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerStatsService.instance,
      builder: (context, _) {
        final completedStars = PlayerStatsService.instance.lessonStars;
        final int totalStars = completedStars.values.fold(0, (sum, val) => sum + val);
        final int totalSteps = modules.fold(0, (sum, m) => sum + m.steps.length);
        final int maxStars = totalSteps * 3;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Trilha de Maestria', style: AppTypography.titleLarge),
            backgroundColor: AppColors.surface,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.chessGold, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalStars / $maxStars',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: modules.length,
              itemBuilder: (context, modIdx) {
                final module = modules[modIdx];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Banner do Módulo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.chessGreen.withOpacity(0.35), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.chessGreen.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.military_tech_rounded, color: AppColors.chessGreen, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  module.title,
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(module.description, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),

                    // Trilha de Passos com conectores e curva senoidal contínua
                    ...List.generate(module.steps.length, (stepIdx) {
                      final step = module.steps[stepIdx];
                      final stars = completedStars[step.id] ?? 0;
                      // Primeiro passo de cada módulo ou passo anterior concluído desbloqueia
                      final isUnlocked = stepIdx == 0 || (completedStars[module.steps[stepIdx - 1].id] ?? 0) > 0;
                      const offsets = [-46.0, 0.0, 46.0, 0.0];
                      final double xOffset = offsets[stepIdx % offsets.length];
                      final double prevOffset = stepIdx > 0 ? offsets[(stepIdx - 1) % offsets.length] : 0.0;

                      return Column(
                        children: [
                          if (stepIdx > 0)
                            TrailConnectorSegment(
                              fromOffsetX: prevOffset,
                              toOffsetX: xOffset,
                              isCompleted: stars > 0,
                              height: 32,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Transform.translate(
                              offset: Offset(xOffset, 0),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: isUnlocked ? () => _openLesson(step) : null,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isUnlocked
                                            ? (stars > 0 ? AppColors.chessGreen : AppColors.surfaceElevated)
                                            : AppColors.surfaceElevated.withOpacity(0.5),
                                        border: Border.all(
                                          color: isUnlocked
                                              ? (stars > 0 ? Colors.white : AppColors.chessGreen)
                                              : AppColors.textMuted.withOpacity(0.3),
                                          width: 3.5,
                                        ),
                                        boxShadow: [
                                          if (isUnlocked)
                                            BoxShadow(
                                              color: AppColors.chessGreen.withOpacity(0.35),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                        ],
                                      ),
                                      child: Icon(
                                        isUnlocked
                                            ? (stars > 0 ? Icons.check_rounded : Icons.play_arrow_rounded)
                                            : Icons.lock_outline_rounded,
                                        color: isUnlocked
                                            ? (stars > 0 ? Colors.white : AppColors.chessGreen)
                                            : AppColors.textMuted,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      step.title,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                                        fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        3,
                                        (i) => Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: i < stars ? AppColors.chessGold : AppColors.textMuted.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    const Divider(color: AppColors.surfaceElevated, height: 44, thickness: 1.5),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LessonBottomSheet extends StatefulWidget {
  final ChessRustFfi ffi;
  final LessonStep step;
  final Function(int stars) onCompleted;

  const _LessonBottomSheet({
    required this.ffi,
    required this.step,
    required this.onCompleted,
  });

  @override
  State<_LessonBottomSheet> createState() => _LessonBottomSheetState();
}

class _LessonBottomSheetState extends State<_LessonBottomSheet> {
  int currentExerciseIdx = 0;
  bool isTheoryPhase = true;
  Pointer<Void>? _exGame;
  String feedbackMessage = '';
  bool isWrongMove = false;

  @override
  void initState() {
    super.initState();
    _loadExerciseGame();
  }

  void _loadExerciseGame() {
    if (widget.step.exercises.isNotEmpty && currentExerciseIdx < widget.step.exercises.length) {
      if (_exGame != null) {
        widget.ffi.freeGame(_exGame!);
      }
      _exGame = widget.ffi.newGameFromFen(widget.step.exercises[currentExerciseIdx].initialFen);
      feedbackMessage = widget.step.exercises[currentExerciseIdx].instruction;
      isWrongMove = false;
    }
  }

  @override
  void dispose() {
    if (_exGame != null) {
      widget.ffi.freeGame(_exGame!);
      _exGame = null;
    }
    super.dispose();
  }

  void _onMovePlayed(String uci) {
    if (widget.step.exercises.isEmpty) return;
    final currentEx = widget.step.exercises[currentExerciseIdx];

    if (currentEx.solutionUciMoves.contains(uci)) {
      // Lance correto!
      if (currentExerciseIdx + 1 < widget.step.exercises.length) {
        setState(() {
          currentExerciseIdx += 1;
          _loadExerciseGame();
        });
      } else {
        widget.onCompleted(3);
      }
    } else {
      // Lance incorreto: reinicia o tabuleiro do exercício para nova tentativa
      setState(() {
        isWrongMove = true;
        feedbackMessage = 'Lance incorreto! Dica: ${currentEx.hint}';
        if (_exGame != null) {
          widget.ffi.freeGame(_exGame!);
        }
        _exGame = widget.ffi.newGameFromFen(currentEx.initialFen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.step.exercises;
    final currentEx = exercises.isNotEmpty && currentExerciseIdx < exercises.length ? exercises[currentExerciseIdx] : null;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const PawnLogo(size: 26, color: AppColors.chessGreen, hasBadge: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.step.title,
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isTheoryPhase) ...[
            ChessBalloonCard(
              type: BalloonType.coach,
              tail: BubbleTail.top,
              avatar: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.chessGreen.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book, color: AppColors.chessGreen, size: 18),
              ),
              title: 'Fundamento Teórico',
              message: widget.step.shortTheory,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isTheoryPhase = false;
                  });
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'COMEÇAR EXERCÍCIOS PRÁTICOS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chessGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else if (currentEx != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentExerciseIdx + 1) / exercises.length,
                backgroundColor: AppColors.surfaceElevated,
                color: AppColors.chessGreen,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            ChessBalloonCard(
              type: isWrongMove ? BalloonType.error : BalloonType.neutral,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              avatar: Icon(
                isWrongMove ? Icons.error_outline : Icons.flag_rounded,
                color: isWrongMove ? AppColors.moveBlunder : AppColors.chessGreen,
                size: 20,
              ),
              title: 'Desafio ${currentExerciseIdx + 1} de ${exercises.length}',
              message: feedbackMessage,
            ),
            const SizedBox(height: 14),
            if (_exGame != null)
              ChessBoardWidget(
                ffi: widget.ffi,
                game: _exGame!,
                onMovePlayed: _onMovePlayed,
              ),
            const SizedBox(height: 12),
            ChessBalloonCard(
              type: BalloonType.hint,
              tail: BubbleTail.bottom,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              avatar: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.chessGold, size: 20),
              title: 'Dica do Mestre',
              message: currentEx.hint,
            ),
          ],
        ],
      ),
    );
  }
}
