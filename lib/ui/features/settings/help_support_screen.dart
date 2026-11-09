import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/chess_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Central de Ajuda & Guia chessD'),
        backgroundColor: theme.surfaceColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Boas-Vindas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryCyan.withOpacity(0.18),
                  AppColors.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.primaryCyan, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guia Completo do chessD', style: AppTypography.titleLarge.copyWith(color: AppColors.primaryCyan)),
                      const SizedBox(height: 4),
                      Text(
                        'Aprenda como utilizar o multiplayer online gratuito, dominar as regras oficiais FIDE e explorar todos os 17 recursos do app.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção 1: Multiplayer Online P2P Custo Zero
          _buildCategoryHeader('Multiplayer Online Custo Zero', Icons.wifi_tethering),
          _buildHelpCard(
            theme: theme,
            title: 'Como funciona o Multiplayer Custo Zero?',
            content: 'O chessD adota uma arquitetura híbrida de alta tecnologia:\n\n'
                '1. WebRTC P2P Direto: A partida ocorre diretamente de celular para celular através de canais de dados de baixa latência, utilizando servidores STUN públicos e gratuitos do Google (stun.l.google.com:19302).\n\n'
                '2. Borda Serverless (Cloudflare Workers): Um micro-serviço serverless atua na sinalização inicial da sala e como retransmissor de contingência sob a cota gratuita de 100.000 requisições diárias.\n\n'
                'O custo operacional para você é R\$ 0,00 perpétuo, sem servidores dedicados ou mensalidades.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Como criar uma sala e convidar um amigo?',
            content: '1. No menu principal, toque no cartão "Multiplayer Online P2P".\n'
                '2. Escolha o controle de tempo desejado (Bullet 1m, Blitz 3+2s, Rápida 5+3s ou Clássica 10+5s) e a sua cor preferida.\n'
                '3. Toque em "Criar Sala & Gerar Código".\n'
                '4. Um código de 6 caracteres (ex: K9W2B4) será gerado. Toque no ícone de cópia e envie para seu amigo pelo WhatsApp ou mensagem.\n'
                '5. Assim que seu amigo colar o código e tocar em "Conectar", a partida iniciará imediatamente.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'O que é a Compensação de Lag SNTP?',
            content: 'O chessD implementa o algoritmo canônico SNTP em Rust (network_protocol.rs) que mede o tempo de ida e volta (RTT) dos pacotes. '
                'Se a internet de um jogador oscilar no 4G/Wi-Fi, o motor credita o atraso de transmissão até um limite seguro de 200 ms, impedindo que o tempo esgote injustamente.',
          ),
          const SizedBox(height: 16),

          // Seção 2: Regras Oficiais FIDE
          _buildCategoryHeader('Regras Oficiais FIDE', Icons.menu_book_outlined),
          _buildHelpCard(
            theme: theme,
            title: 'Roque Menor e Roque Maior (O-O e O-O-O)',
            content: 'O roque é um lance especial entre o Rei e a Torre que protege o monarca e conecta as torres.\n\n'
                'Condições obrigatórias segundo a FIDE:\n'
                '• Nem o Rei nem a Torre escolhida podem ter se movido anteriormente na partida.\n'
                '• Todas as casas entre o Rei e a Torre devem estar completamente desocupadas.\n'
                '• O Rei não pode estar em xeque no momento do roque.\n'
                '• Nenhuma das casas por onde o Rei passar (ou na qual parar) pode estar sob ataque de peças adversárias.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Captura En Passant (Na Passagem)',
            content: 'Quando um peão avança duas casas a partir da sua posição inicial e para ao lado de um peão adversário, este peão adversário pode capturá-lo "na passagem", como se ele tivesse avançado apenas uma casa.\n\n'
                'Atenção: A captura En Passant só é válida estritamente no lance imediatamente seguinte ao avanço duplo. Se não for executada na jogada seguinte, o direito é perdido.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Critérios de Empate no Xadrez',
            content: 'O xadrez termina em empate nos seguintes casos:\n\n'
                '• Afogamento (Stalemate): O jogador da vez não está em xeque, mas não possui nenhum lance legal disponível.\n'
                '• Insuficiência Material: Nenhum dos lados possui peças suficientes para aplicar xeque-mate (ex: Rei contra Rei, Rei e Bispo contra Rei, Rei e Cavalo contra Rei).\n'
                '• Repetição de Três Posições: A mesma posição exata do tabuleiro se repete 3 vezes com o mesmo jogador na vez e mesmos direitos de roque/en passant.\n'
                '• Regra dos 50 Lances: 50 lances consecutivos de ambos os lados sem nenhuma captura de peça e sem nenhum avanço de peão.\n'
                '• Acordo Mútuo: Os jogadores propõem e aceitam o empate amigável.',
          ),
          const SizedBox(height: 16),

          // Seção 3: Modos e Ferramentas Exclusivas
          _buildCategoryHeader('Recursos Avançados chessD', Icons.stars_outlined),
          _buildHelpCard(
            theme: theme,
            title: 'Revisão CAPS2 & Detector de Tilt',
            content: 'A Revisão de Partidas utiliza a fórmula do CAPS2 para avaliar a precisão algorítmica de cada lance comparada à melhor variante do Stockfish. '
                'O Detector de Tilt monitora se após um erro grave o jogador começou a jogar rápido demais por frustração, gerando alertas didáticos.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Treinador de Repertório SM-2',
            content: 'O algoritmo SuperMemo SM-2 calcula intervalos matemáticos espaçados (1 dia, 6 dias, multiplicação pelo Fator de Facilidade EF) para fixar variantes teóricas de abertura na memória de longo prazo.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Perícia Anti-Cheat (Ken Regan)',
            content: 'Módulo estatístico baseado na metodologia do assessor da FIDE Professor Kenneth Regan. Avalia concordância com o Top-1/Top-2 da engine, perda média de centipeões (ACL) e desvio padrão de tempo para identificar auxílio computacional.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Espelhamento Wi-Fi Cast para Smart TVs',
            content: 'O chessD possui um servidor HTTP embarcado. Na tela de Acervo & Cast, toque em "Iniciar Transmissão Local" e abra o endereço exibido (ex: http://192.168.1.50:8080) em qualquer Smart TV ou navegador da mesma rede Wi-Fi para ver o tabuleiro ao vivo.',
          ),
          const SizedBox(height: 16),

          // Seção 4: Perguntas Frequentes (FAQ)
          _buildCategoryHeader('Perguntas Frequentes (FAQ)', Icons.quiz_outlined),
          _buildHelpCard(
            theme: theme,
            title: 'O aplicativo funciona sem conexão com a internet?',
            content: 'Sim! 16 dos 17 modos (Puzzles, Trilha de Maestria, Batalha contra Bots, Análise CAPS2, Torneios Suíço, SM-2, Fischer Random e Pass & Play) rodam 100% offline no seu dispositivo através do núcleo nativo em Rust. Apenas o Multiplayer Online exige rede para conectar os dois aparelhos.',
          ),
          _buildHelpCard(
            theme: theme,
            title: 'Como personalizar as cores do tabuleiro e das peças?',
            content: 'Toque no ícone de paleta na barra superior da tela inicial ou no cartão "Personalização Visual & Paletas". Você pode alternar entre Modo Claro e Modo Noite, escolher entre 8 temas de tabuleiro, 5 estilos de peças e 6 cores de acento com visualização em tempo real.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryCyan),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required ThemeController theme,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
        title: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: theme.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
}
