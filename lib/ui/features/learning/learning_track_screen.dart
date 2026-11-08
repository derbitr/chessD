import 'package:flutter/material.dart';
import 'package:chess_d/data/models/lesson_module.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
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
  final Map<String, int> completedStars = {'step_1_1_checkmate': 3}; // Inicial com primeiro nó completo

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
          setState(() {
            completedStars[step.id] = stars;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trilha de Maestria (Estilo Duolingo)', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          itemCount: modules.length,
          itemBuilder: (context, modIdx) {
            final module = modules[modIdx];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header do Módulo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.military_tech, color: AppColors.secondaryAmber, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(module.title, style: AppTypography.titleLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(module.description, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),

                // Trilha Senoidal Vertical de Nós
                ...List.generate(module.steps.length, (stepIdx) {
                  final step = module.steps[stepIdx];
                  final stars = completedStars[step.id] ?? 0;
                  final isUnlocked = stepIdx == 0 || (completedStars[module.steps[stepIdx - 1].id] ?? 0) > 0;

                  // Deslocamento senoidal lateral (Duolingo winding curve)
                  final double xOffset = (stepIdx % 2 == 0) ? -35.0 : 35.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Transform.translate(
                      offset: Offset(xOffset, 0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: isUnlocked ? () => _openLesson(step) : null,
                            child: Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? (stars > 0 ? AppColors.accentEmerald : AppColors.primaryCyan)
                                    : AppColors.surfaceElevated,
                                border: Border.all(
                                  color: isUnlocked ? Colors.white : AppColors.textMuted,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  if (isUnlocked)
                                    BoxShadow(
                                      color: (stars > 0 ? AppColors.accentEmerald : AppColors.primaryCyan).withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Icon(
                                isUnlocked
                                    ? (stars > 0 ? Icons.check : Icons.star)
                                    : Icons.lock,
                                color: isUnlocked ? Colors.black : AppColors.textMuted,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                          if (stars > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                3,
                                (i) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < stars ? AppColors.secondaryAmber : AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(color: AppColors.surfaceElevated, height: 48, thickness: 2),
              ],
            );
          },
        ),
      ),
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
  late dynamic _exGame;

  @override
  void initState() {
    super.initState();
    if (widget.step.exercises.isNotEmpty) {
      _exGame = widget.ffi.newGameFromFen(widget.step.exercises[0].initialFen);
    }
  }

  @override
  void dispose() {
    if (widget.step.exercises.isNotEmpty) {
      widget.ffi.freeGame(_exGame);
    }
    super.dispose();
  }

  void _onMovePlayed(String uci) {
    final currentEx = widget.step.exercises[currentExerciseIdx];
    if (currentEx.solutionUciMoves.contains(uci)) {
      // Acertou o lance!
      if (currentExerciseIdx + 1 < widget.step.exercises.length) {
        setState(() {
          currentExerciseIdx += 1;
          widget.ffi.freeGame(_exGame);
          _exGame = widget.ffi.newGameFromFen(widget.step.exercises[currentExerciseIdx].initialFen);
        });
      } else {
        // Concluiu todos os exercícios!
        widget.onCompleted(3);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.step.exercises;
    final currentEx = exercises.isNotEmpty ? exercises[currentExerciseIdx] : null;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.step.title, style: AppTypography.displayMedium),
          const SizedBox(height: 12),

          if (isTheoryPhase) ...[
            Text(widget.step.shortTheory, style: AppTypography.bodyLarge),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isTheoryPhase = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('COMEÇAR EXERCÍCIOS PRÁTICOS', style: AppTypography.labelLarge),
              ),
            ),
          ] else if (currentEx != null) ...[
            // Barra de progresso dos exercícios
            LinearProgressIndicator(
              value: (currentExerciseIdx + 1) / exercises.length,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.accentEmerald,
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            Text(currentEx.instruction, style: AppTypography.bodyLarge),
            const SizedBox(height: 12),
            ChessBoardWidget(
              ffi: widget.ffi,
              game: _exGame,
              onMovePlayed: _onMovePlayed,
            ),
            const SizedBox(height: 12),
            Text('Dica: ${currentEx.hint}', style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}
