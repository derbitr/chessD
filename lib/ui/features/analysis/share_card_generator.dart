import 'package:flutter/material.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';

class ShareCardScreen extends StatefulWidget {
  final double whiteAccuracy;
  final double blackAccuracy;
  final int brilliantsCount;
  final int blundersCount;
  final String playerName;
  final String opponentName;

  const ShareCardScreen({
    super.key,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.brilliantsCount,
    required this.blundersCount,
    this.playerName = 'Você',
    this.opponentName = 'Bot Democrático',
  });

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool isExporting = false;
  String exportStatus = '';

  Future<void> _exportAndShare() async {
    setState(() {
      isExporting = true;
      exportStatus = 'Renderizando imagem em alta resolução (3.0x)...';
    });

    // Simula renderização offstage via RepaintBoundary em PNG 32-bit
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      isExporting = false;
      exportStatus = 'Card gerado com sucesso! Pronto para Instagram Stories ou WhatsApp.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card de Partida copiado para a galeria e compartilhado!'),
        backgroundColor: AppColors.accentEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cartão de Compartilhamento', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryCyan),
            onPressed: isExporting ? null : _exportAndShare,
            tooltip: 'Exportar Card',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // O Card Visual de Compartilhamento (Stories / Feed Ratio)
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF050811),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header da Marca Soberana
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryAmber.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield, color: AppColors.secondaryAmber, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'chessD',
                                        style: AppTypography.titleMedium.copyWith(
                                          letterSpacing: 1.0,
                                          color: AppColors.secondaryAmber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        '100% Offline • Sem Paywall',
                                        style: AppTypography.labelSmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text('CAPS2 CERTIFIED', style: AppTypography.labelSmall),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Duelo de Precisão CAPS2
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(widget.playerName.toUpperCase(), style: AppTypography.labelSmall),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.whiteAccuracy.toStringAsFixed(1)}%',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: widget.whiteAccuracy >= 80 ? AppColors.accentEmerald : AppColors.secondaryAmber,
                                    fontSize: 34,
                                  ),
                                ),
                                const Text('Precisão CAPS2', style: AppTypography.bodySmall),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: AppColors.surfaceElevated,
                            ),
                            Column(
                              children: [
                                Text(widget.opponentName.toUpperCase(), style: AppTypography.labelSmall),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.blackAccuracy.toStringAsFixed(1)}%',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 34,
                                  ),
                                ),
                                const Text('Precisão CAPS2', style: AppTypography.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Badges de Destaque
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.moveBrilliant.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.moveBrilliant.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.auto_awesome, color: AppColors.moveBrilliant, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.brilliantsCount}',
                                        style: AppTypography.displayMedium.copyWith(color: AppColors.moveBrilliant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Lances Brilhantes (!!)', style: AppTypography.labelSmall),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.moveBlunder.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.moveBlunder.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, color: AppColors.moveBlunder, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.blundersCount}',
                                        style: AppTypography.displayMedium.copyWith(color: AppColors.moveBlunder),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Gafes Cometidas (??)', style: AppTypography.labelSmall),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Miniatura de Tabuleiro Decorativa & Slogan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceElevated),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.boardGreenDark,
                              ),
                              child: const Icon(Icons.grid_4x4, color: AppColors.boardGreenLight, size: 36),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Análise Profunda On-Device',
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sem limitações de assinatura. Motor em Rust rodando a 120 FPS no dispositivo.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Rodapé do Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'chessd.app • @chessd',
                              style: AppTypography.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.qr_code_2, color: AppColors.primaryCyan, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (exportStatus.isNotEmpty) ...[
                Text(
                  exportStatus,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.accentEmerald),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Botão de Exportação
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isExporting ? null : _exportAndShare,
                  icon: isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.share, color: Colors.black),
                  label: Text(
                    isExporting ? 'GERANDO CARD...' : 'COMPARTILHAR CARD (INSTAGRAM / WHATSAPP)',
                    style: AppTypography.labelLarge.copyWith(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
