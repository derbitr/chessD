import 'package:flutter/material.dart';
import 'package:soberano_chess/services/chess_rust_ffi.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';

class AntiCheatAuditScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const AntiCheatAuditScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<AntiCheatAuditScreen> createState() => _AntiCheatAuditScreenState();
}

class _AntiCheatAuditScreenState extends State<AntiCheatAuditScreen> {
  bool isAuditing = false;
  Map<String, dynamic>? auditResult;
  String currentScenario = 'adversario_suspeito';

  @override
  void initState() {
    super.initState();
    _runAudit(currentScenario);
  }

  void _runAudit(String scenario) {
    setState(() {
      isAuditing = true;
      currentScenario = scenario;
    });

    List<String> moves;
    List<String> top1;
    List<String> top2;
    List<int> cpls;
    List<int> times;

    if (scenario == 'adversario_suspeito') {
      // Cenário com 16 lances de precisão extrema de Stockfish e cadência de 1.2s constante
      moves = List.generate(16, (i) => 'move_$i');
      top1 = List.generate(16, (i) => 'move_$i');
      top2 = List.generate(16, (i) => 'move_$i');
      cpls = List.generate(16, (i) => 4); // 4 cp loss
      times = List.generate(16, (i) => 1200); // 1200ms constante (robô)
    } else {
      // Cenário humano natural
      moves = ['e2e4', 'g1f3', 'd2d4', 'c2c4', 'b1c3', 'f1d3', 'e1g1', 'c1e3'];
      top1 = ['e2e4', 'd2d4', 'c2c4', 'g1f3', 'b1c3', 'c1e3', 'e1g1', 'f1d3'];
      top2 = ['d2d4', 'g1f3', 'e2e4', 'c2c4', 'f1c4', 'f1d3', 'e1g1', 'd1e2'];
      cpls = [0, 15, 30, 45, 10, 80, 5, 25];
      times = [800, 2400, 1500, 4800, 3100, 9200, 1200, 3400];
    }

    final res = widget.ffi.auditAntiCheat(
      movesPlayed: moves,
      engineTop1: top1,
      engineTop2: top2,
      centipawnLosses: cpls,
      moveTimesMs: times,
    );

    setState(() {
      auditResult = res;
      isAuditing = false;
    });
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'Clean': return AppColors.accentEmerald;
      case 'Inconclusive': return AppColors.primaryCyan;
      case 'Suspicious': return AppColors.secondaryAmber;
      case 'HighlyAnomalous': return AppColors.moveBlunder;
      default: return AppColors.textPrimary;
    }
  }

  String _getVerdictTitle(String verdict) {
    switch (verdict) {
      case 'Clean': return 'PADRÃO HUMANO LEGÍTIMO';
      case 'Inconclusive': return 'INCONCLUSIVO / EQUILIBRADO';
      case 'Suspicious': return 'PADRÃO SUSPEITO DE ASSISTÊNCIA';
      case 'HighlyAnomalous': return 'ANOMALIA EXTREMA (BOT DETECTADO)';
      default: return verdict;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verdict = auditResult?['verdict'] as String? ?? 'Clean';
    final cps = (auditResult?['cheat_probability_score'] as num?)?.toDouble() ?? 0.0;
    final top1Pct = (auditResult?['top1_match_pct'] as num?)?.toDouble() ?? 0.0;
    final top2Pct = (auditResult?['top2_match_pct'] as num?)?.toDouble() ?? 0.0;
    final acl = (auditResult?['average_centipawn_loss'] as num?)?.toDouble() ?? 0.0;
    final stdDev = (auditResult?['move_time_std_dev_ms'] as num?)?.toDouble() ?? 0.0;
    final explanation = auditResult?['forensic_explanation'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perícia Forense Anti-Cheat', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seletor de Cenário de Teste
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Auditar Oponente Anômalo'),
                      selected: currentScenario == 'adversario_suspeito',
                      selectedColor: AppColors.moveBlunder,
                      onSelected: (_) => _runAudit('adversario_suspeito'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Auditar Partida Humana'),
                      selected: currentScenario == 'humano_normal',
                      selectedColor: AppColors.accentEmerald,
                      onSelected: (_) => _runAudit('humano_normal'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Painel do Veredito Principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getVerdictColor(verdict), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      verdict == 'HighlyAnomalous' || verdict == 'Suspicious'
                          ? Icons.warning_amber_rounded
                          : Icons.verified_user,
                      size: 56,
                      color: _getVerdictColor(verdict),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getVerdictTitle(verdict),
                      style: AppTypography.titleLarge.copyWith(color: _getVerdictColor(verdict), fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Probabilidade de Assistência: ${cps.toStringAsFixed(1)}%',
                      style: AppTypography.displayMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text('PARÂMETROS ESTATÍSTICOS DA PERÍCIA (FIDE REGAN)', style: AppTypography.labelSmall),
              const SizedBox(height: 8),

              // Métricas em Grade
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'TOP-1 ENGINE',
                      value: '${top1Pct.toStringAsFixed(1)}%',
                      subtitle: 'Esperado humano: 55-70%',
                      isWarning: top1Pct > 80.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'TOP-2 ENGINE',
                      value: '${top2Pct.toStringAsFixed(1)}%',
                      subtitle: 'Concordância ampla',
                      isWarning: top2Pct > 90.0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'PERDA CENTIPAWNS (ACL)',
                      value: '${acl.toStringAsFixed(1)} cp',
                      subtitle: 'GMs de elite: 15-25 cp',
                      isWarning: acl < 10.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'DESVIO TEMPO',
                      value: '${stdDev.toStringAsFixed(0)} ms',
                      subtitle: 'Cadência robótica < 400ms',
                      isWarning: stdDev < 400.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required bool isWarning,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isWarning ? AppColors.moveBlunder.withOpacity(0.5) : AppColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: isWarning ? AppColors.moveBlunder : AppColors.primaryCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
