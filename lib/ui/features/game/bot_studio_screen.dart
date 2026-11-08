import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
import 'package:chess_d/ui/core/app_typography.dart';
import 'package:chess_d/ui/core/chess_balloon.dart';
import 'package:chess_d/ui/core/pawn_logo.dart';
import 'bot_game_screen.dart';

class BotStudioScreen extends StatefulWidget {
  final ChessRustFfi ffi;

  const BotStudioScreen({
    super.key,
    required this.ffi,
  });

  @override
  State<BotStudioScreen> createState() => _BotStudioScreenState();
}

class _BotStudioScreenState extends State<BotStudioScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Gladiador Cibernético');
  double botElo = 1500;
  int personality = 1; // 0 = Classical, 1 = Aggressive, 2 = Positional

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getPersonalityName(int p) {
    switch (p) {
      case 1: return 'Agressivo / Tático';
      case 2: return 'Posicional / Estrutural';
      default: return 'Clássico / Equilibrado';
    }
  }

  String _getPersonalityDescription(int p) {
    switch (p) {
      case 1: return 'Prioriza linhas de ataque direto ao Rei adversário, sacrifícios táticos e aberturas abertas.';
      case 2: return 'Foca no controle de colunas abertas, postos avançados de cavalo e finais técnicos com vantagem mínima.';
      default: return 'Distribuição harmônica entre desenvolvimento sólido e cálculo de variantes objetivas.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estúdio de Criação de Bots', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Padronizado & Perfil do Bot no Estilo Chess.com
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryCyan.withOpacity(0.25),
                                AppColors.primaryCyan.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.5), width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.smart_toy, size: 44, color: AppColors.primaryCyan),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Nome do Bot',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Balão de Fala do Bot
              ChessBalloonCard(
                type: BalloonType.coach,
                tail: BubbleTail.top,
                avatar: const PawnLogo(size: 20, color: AppColors.primaryCyan, hasBadge: false),
                title: 'Desafio do Bot',
                message: 'Configure meu nível de cálculo e estilo tático abaixo. Estou calibrado para jogar partidas competitivas!',
              ),

              const SizedBox(height: 20),

              // Seletor de Elo
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FORÇA DE CÁLCULO (ELO)', style: AppTypography.labelSmall),
                        Text(
                          '${botElo.toInt()} Elo',
                          style: AppTypography.titleLarge.copyWith(color: AppColors.primaryCyan),
                        ),
                      ],
                    ),
                    Slider(
                      value: botElo,
                      min: 400,
                      max: 2400,
                      divisions: 40,
                      activeColor: AppColors.primaryCyan,
                      inactiveColor: AppColors.surfaceElevated,
                      onChanged: (val) {
                        setState(() {
                          botElo = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seletor de Personalidade
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERSONALIDADE & ESTILO TÁTICO', style: AppTypography.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      _getPersonalityName(personality),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Clássico'),
                            selected: personality == 0,
                            selectedColor: AppColors.primaryCyan,
                            onSelected: (_) => setState(() => personality = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Agressivo'),
                            selected: personality == 1,
                            selectedColor: AppColors.secondaryAmber,
                            onSelected: (_) => setState(() => personality = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Posicional'),
                            selected: personality == 2,
                            selectedColor: AppColors.accentEmerald,
                            onSelected: (_) => setState(() => personality = 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getPersonalityDescription(personality),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Botão Desafiar
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BotGameScreen(
                          ffi: widget.ffi,
                          botElo: botElo.toInt(),
                          botPersonality: personality,
                          botName: _nameController.text.isNotEmpty ? _nameController.text : 'Bot Personalizado',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    'JOGAR CONTRA ESTE BOT',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
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
