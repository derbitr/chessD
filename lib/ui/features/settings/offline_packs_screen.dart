import 'package:flutter/material.dart';
import 'package:soberano_chess/services/wifi_cast_server.dart';
import 'package:soberano_chess/ui/core/app_colors.dart';
import 'package:soberano_chess/ui/core/app_typography.dart';

class OfflinePacksScreen extends StatefulWidget {
  final WifiCastServer castServer;

  const OfflinePacksScreen({
    super.key,
    required this.castServer,
  });

  @override
  State<OfflinePacksScreen> createState() => _OfflinePacksScreenState();
}

class _OfflinePacksScreenState extends State<OfflinePacksScreen> {
  bool isCastActive = false;
  String castUrl = '';

  final List<Map<String, dynamic>> packs = [
    {
      'title': 'Pacote Base Tático Essencial',
      'puzzles_count': '20.000 puzzles',
      'size_zst': '1.2 MB (Zstandard Nível 9)',
      'is_installed': true,
      'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    },
    {
      'title': 'Acervo Mestre de Finais & Tática',
      'puzzles_count': '500.000 puzzles',
      'size_zst': '28.5 MB',
      'is_installed': false,
      'sha256': '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
    },
    {
      'title': 'Biblioteca Universal de Partidas Lichess/FIDE',
      'puzzles_count': '4.200.000 puzzles',
      'size_zst': '184.2 MB',
      'is_installed': false,
      'sha256': 'cb238752a788e8067e4fe33ec36a4f9f7d08595cb64c52f6f59d93bbcf793424',
    },
  ];

  @override
  void initState() {
    super.initState();
    isCastActive = widget.castServer.isRunning;
    if (isCastActive) {
      castUrl = 'http://${widget.castServer.localIpAddress}:${widget.castServer.port}';
    }
  }

  Future<void> _toggleWifiCast(bool enable) async {
    if (enable) {
      final ok = await widget.castServer.start();
      setState(() {
        isCastActive = ok;
        castUrl = 'http://${widget.castServer.localIpAddress}:${widget.castServer.port}';
      });
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wi-Fi Cast iniciado em $castUrl'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
      }
    } else {
      await widget.castServer.stop();
      setState(() {
        isCastActive = false;
        castUrl = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Acervo Offline & Conectividade', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Painel do Servidor Wi-Fi Cast (Smart TV)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isCastActive ? AppColors.accentEmerald : AppColors.surfaceElevated),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cast_connected, color: isCastActive ? AppColors.accentEmerald : AppColors.textMuted),
                          const SizedBox(width: 10),
                          const Text('Espelhamento Wi-Fi Cast', style: AppTypography.titleMedium),
                        ],
                      ),
                      Switch(
                        value: isCastActive,
                        activeThumbColor: AppColors.accentEmerald,
                        activeTrackColor: AppColors.accentEmerald.withAlpha(128),
                        onChanged: _toggleWifiCast,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transmita o tabuleiro em tempo real para qualquer Smart TV ou PC na sua rede Wi-Fi local sem internet.',
                    style: AppTypography.bodySmall,
                  ),
                  if (isCastActive) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.primaryCyan, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              castUrl,
                              style: const TextStyle(color: AppColors.primaryCyan, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('PACOTES DE EXPANSÃO TÁTICA (ZSTANDARD .ZST)', style: AppTypography.labelSmall),
            const SizedBox(height: 8),

            ...packs.map((p) {
              final isInst = p['is_installed'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isInst ? AppColors.accentEmerald.withOpacity(0.5) : AppColors.surfaceElevated),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isInst ? AppColors.accentEmerald.withOpacity(0.12) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isInst ? Icons.download_done : Icons.cloud_download_outlined,
                        color: isInst ? AppColors.accentEmerald : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title'] as String, style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text('${p['puzzles_count']} · ${p['size_zst']}', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (isInst)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ATIVO', style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            p['is_installed'] = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pacote ${p['title']} verificado e ativado!'),
                              backgroundColor: AppColors.accentEmerald,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('BAIXAR', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
