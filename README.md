# chessD

Plataforma autônoma de xadrez, estudo tático gamificado e perícia analítica de partidas, desenvolvida com Flutter 3.47 e Rust 1.96. Totalmente offline, gratuito e sem cobrança por recursos analíticos.

**Central de Downloads e Releases Oficiais:**
- **Versao Mais Recente (v1.0.5):** [Acessar Release v1.0.5 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.5)
- **Download Direto para Android (APK):** [chessD-v1.0.5-android.apk](https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-android.apk)
- **Download Direto para Windows (64-bit):** [chessD-v1.0.5-windows-x64.zip](https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-windows-x64.zip)
- **Catalogo Completo de Releases:** [github.com/derbitr/chessD/releases](https://github.com/derbitr/chessD/releases)

---

## 1. Visão Geral do Projeto

O chessD é um aplicativo de xadrez de alta performance projetado sob o princípio da total privacidade e autonomia do usuário. Ao contrário de plataformas comerciais baseadas em assinaturas recorrentes (como as modalidades Platinum e Diamond de plataformas online), o chessD executa 100% das suas rotinas de validação de regras FIDE, geração de lances, busca minimax, árvores de abertura, repetição espaçada e cálculo de precisão algorítmica diretamente no dispositivo do usuário, sem emitir telemetria nem demandar conexão com a internet.

A infraestrutura foi construída combinando a expressividade e fluidez gráfica do Flutter (renderização a 120 FPS com suporte a gestos e temas de alto contraste) com a segurança de memória, determinismo e velocidade do Rust compilado para código nativo de máquina via Foreign Function Interface (FFI).

---

## 2. Comparativo de Recursos: chessD vs. Plataformas Comerciais

| Funcionalidade | Plataformas Comerciais (Plano Gratuito) | Plataformas Comerciais (Diamond / \$120+/ano) | chessD (100% Gratuito e Livre) |
| :--- | :--- | :--- | :--- |
| Revisão de Partidas com Precisão CAPS2 | 1 análise por dia ou paywall | Ilimitada via nuvem proprietária | Ilimitada e Instantânea no dispositivo (Rust Core) |
| Classificação de Lances (Brilhante, Melhor, Erro) | Oculta ou restrita | Exibida após processamento em servidor | Processamento local em milissegundos |
| Repetição de Erros Guiada (Retry Mistakes) | Bloqueada sob assinatura | Liberada | Liberada nativamente com orientação de motor |
| Trilha Gamificada de Aprendizado | Parcial ou com anúncios | Liberada | Trilha completa por seções, estrelas e módulos |
| Banco de Puzzles Táticos | Limite de 3 a 5 puzzles diários | Ilimitado | Ilimitado offline via compressão Zstandard |
| Treinador de Repertório com SM-2 | Inexistente ou módulo pago separado | Disponível em apps externos por assinatura | Integrado com algoritmo SuperMemo SM-2 |
| Auditoria Forense Anti-Cheat (Ken Regan) | Ferramenta interna restrita a moderadores | Inacessível ao jogador comum | Acessível para auditoria pericial de qualquer PGN |
| Fischer Random (Chess960) | Restrito a salas de jogo | Disponível | 960 posições oficiais geradas por semente determinística |
| Transmissão Local em Tempo Real (Wi-Fi Cast) | Inexistente (requer login em conta web) | Inexistente (depende de internet) | Servidor HTTP integrado para Smart TVs e navegadores locais |
| Privacidade e Custódia de Dados | Dados monitorados e monetizados | Dados rastreados em servidores terceiros | 100% Offline, zero telemetria e código auditável |

---

## 3. Arquitetura de Software

O sistema adota uma divisão rigorosa de responsabilidades entre interface declarativa e motor lógico de baixo nível:

```
+-------------------------------------------------------------------------+
|                              FLUTTER UI                                 |
|  - Camada de Apresentacao a 120 FPS (Telas, Modos de Jogo, Graficos)   |
|  - CustomPainters de Tabuleiro, Heatmaps Taticos e Curvas Senoidais     |
|  - Gerenciamento de Estado Reativo (ValueNotifiers e Streams Locais)    |
+-------------------------------------------------------------------------+
                                    |
                            Dart FFI (C-ABI)
                                    |
+-------------------------------------------------------------------------+
|                              RUST CORE                                  |
|  - engine.rs: Bitboards 64-bit, Magic Bitboards, Validador Estrito FIDE |
|  - bot.rs: Minimax com Poda Alpha-Beta, Quiescence Search e Avaliacao   |
|  - chess960.rs: Gerador Canônico dos 960 Arranjos Fischer Random        |
|  - bitboard_heatmap.rs: Mapas de Dominio Espacial e Tensao Tatica       |
|  - rating.rs: Calculo de Elo Glicko/Elo simplificado, Vidas e Streaks   |
|  - game_review.rs: Avaliador CAPS2, Sigmoide de Vitoria e Tilt Tracker  |
|  - srs.rs: Algoritmo de Repeticao Espacada SuperMemo SM-2               |
|  - openings.rs: Catalogo Canônico ECO e Estatisticas Mestres            |
|  - tournament.rs: Emparelhamento Suico FIDE, Buchholz e Sonneborn-B.    |
|  - anti_cheat.rs: Auditoria Forense Estatistica (Modelo Ken Regan)      |
|  - zstd_store.rs: Compressao e Descompressao Zstandard de Partidas      |
+-------------------------------------------------------------------------+
```

### 3.1 Contrato C-ABI e Zero-Copy FFI

A comunicação entre a camada Dart e a biblioteca nativa Rust (`rust_core.dll` no Windows ou `librust_core.so` no Android/Linux) é estabelecida via assinaturas C estritas (`extern "C"`). Todas as transferências de estruturas compostas utilizam serialização JSON em strings UTF-8 terminadas em nulo (`*const c_char`), desalocadas formalmente através de `chess_string_free` para evitar qualquer tipo de vazamento de memória (*memory leaks*).

---

## 4. Catálogo Detalhado de Módulos e Funcionalidades

### 4.1 Tabuleiro Interativo e Notação FIDE
- Renderização vetorial das 64 casas com paleta Dark Glass de alto contraste.
- Arrastar e soltar (*drag-and-drop*) com detecção precisa de coordenadas e feedback tátil.
- Destaque visual de casas de destino legal, captura em curso e indicação de xeque ao rei.
- Histórico completo de lances em notação algébrica padrão (SAN).

### 4.2 Validador de Regras FIDE em Rust
- Representação por Bitboards (`u64`) individuais para cada tipo e cor de peça.
- Validação completa de roque pequeno e grande, com checagem estrita de casas atacadas no trajeto do rei.
- Captura *en passant* com atualização de estado efêmero de peão.
- Promoção de peões para Dama, Torre, Bispo ou Cavalo.
- Detecção algorítmica de xeque-mate, afogamento (*stalemate*), empate por repetição tripla e regra dos 50 lances sem capturas ou movimentos de peão.

### 4.3 Treinador de Coordenadas
- Exercício de fixação mental para localização rápida de casas no tabuleiro (a1 até h8).
- Temporizador com contagem regressiva e apuração contínua de precisão percentual e velocidade média de reação.

### 4.4 Modo Pass and Play Local
- Suporte a confrontos locais entre dois jogadores humanos no mesmo aparelho.
- Inversão automática ou travada de perspectiva de tabuleiro.
- Relógio integrado com incrementos configuráveis.

### 4.5 Batalha contra Bots Nativos
- Calibração analógica contínua e escalonada cobrindo faixas de Elo de 400 a 2400.
- Profundidade de cálculo adaptativa:
  - Elo 400 a 800: profundidade 1 (respostas imediatas).
  - Elo 800 a 1400: profundidade 2 (capturas óbvias e táticas curtas).
  - Elo 1400 a 2000: profundidade 3 (planejamento posicional e combinações).
  - Elo 2000+: profundidade 4+ com poda Alfa-Beta e *Quiescence Search* contra efeito horizonte.
- Taxa de gafe humana estocástica (*Human Blunder Rate*): varia de 50% de imprecisão deliberada em Elo < 600 até 0% absoluto em nível mestre.
- Diversidade dinâmica de lances (*Move Sampling*): amostragem probabilística entre os melhores lances candidatos para evitar partidas repetitivas ou mecânicas.
- 3 perfis de personalidade técnica:
  - **Classica:** Busca equilibrada entre solidez posicional e segurança de rei.
  - **Agressiva:** Bônus de avaliação para xeques (+35 cp) e capturas (+25 cp), forçando ataques à ala do rei.
  - **Posicional:** Ponderação elevada para roque antecipado (+30 cp), estrutura de peões e controle de colunas abertas.

### 4.6 Bot Studio
- Estação de customização onde o usuário pode criar e calibrar seus próprios oponentes sintéticos sob medida, ajustando nomes, Elo específico e personalidades de jogo.

### 4.7 Fischer Random Chess960 e Posições Arbitrárias (FEN)
- Geração determinística dos 960 arranjos iniciais oficiais propostos pelo Grande Mestre Bobby Fischer.
- Garantia matemática de bispos em casas de cores alternadas e rei confinado entre as duas torres.
- Navegação por semente numérica (0 a 959), onde o índice 518 corresponde rigorosamente à posição clássica do xadrez tradicional.
- **Suporte Nativo a Posições Arbitrárias via FEN:** Função `chess_game_create_from_fen` que permite inicializar o motor com qualquer posição legal de xadrez (finais teóricos como Lucena e Philidor, estudos de mate, *Tabiyas* de meio-jogo e modalidades com vantagem material/*Odds Chess*).

### 4.8 Mapas de Calor Tático (Bitboard Heatmaps)
- Mapeamento em tempo real do controle territorial e da tensão de ataque sobre cada casa.
- Sobreposição gráfica translúcida indicando zonas de pressão mútua e fraquezas estruturais.

### 4.9 Trilha de Maestria Gamificada
- Currículo pedagógico estruturado em 7 módulos progressivos (do mate básico à profilaxia de Grande Mestre):
  1. Módulo 1: Fundamentos do Tabuleiro.
  2. Módulo 2: Garfo, Cravada e Espeto.
  3. Módulo 3: Temas Táticos Avançados (Mate Sufocado, Descoberta e Desvio).
  4. Módulo 4: Abertura e Desenvolvimento Rápido.
  5. Módulo 5: Controle Estratégico e Meio-Jogo.
  6. Módulo 6: Finais Clássicos de Reis e Peões.
  7. Módulo 7: Profilaxia e Maestria.
- Visualização em nós interconectados por curvas senoidais contínuas (`TrailConnectorSegment`), bloqueio de módulos dependentes, reset automático de lances incorretos e premiação persistente de até 3 estrelas por lição concluída (`PlayerStatsService`).

### 4.10 Trilha de Quebra-Cabeças (40 Marcos) e Treino de Erros Reais
- Trilha tática contínua com 40 marcos em 5 estágios interconectados em curva S com botões chanfrados estilo Chess.com.
- Integração direta com o modo contínuo em banco compactado, *Puzzle Ladder* com 3 vidas (strikes), bônus de sequência (*streak multiplier*) e Elo tático dinâmico persistido localmente.
- **Treino de Erros Próprios (`UserMistakesService`):** Inicia estritamente zerado (`0 / 0`) sem dados fictícios para novos jogadores e registra automaticamente apenas erros reais cometidos em puzzles ou partidas (com carregamento opcional de exercícios de demonstração).

### 4.11 Sistema de Revisão de Partidas CAPS2 (Chess Accuracy Percentage System)
- Avaliação qualitativa de partidas lance a lance, convertendo a vantagem estática em probabilidade de vitória esperada através da curva logística:

$$\text{WinPct}(\text{eval}) = \frac{1}{1 + 10^{-\text{eval} / 400}}$$

- O índice percentual de acurácia de cada lance é apurado subtraindo a perda de probabilidade relativa ao melhor lance encontrado pelo motor:

$$\text{Accuracy} = 100 \times \left(1 - \frac{\text{WinPct}(\text{best}) - \text{WinPct}(\text{played})}{\max(0.01, \text{WinPct}(\text{best}))}\right)$$

- Classificação canônica dos lances em 7 níveis:
  - **Brilhante:** Lance de sacrifício correto que preserva ou amplia a vantagem.
  - **Melhor Lance:** Lance idêntico à linha principal da engine.
  - **Excelente:** Perda insignificante de probabilidade de vitória.
  - **Bom:** Lance sólido com leve declínio de precisão.
  - **Imprecisao:** Desvio posicional que cede iniciativa ao adversário.
  - **Erro:** Queda substancial de probabilidade de vitória.
  - **Capivara (Blunder):** Inversão grave de desfecho ou perda direta de material.

### 4.12 Detector Forense de Tilt Emocional
- Algoritmo que rastreia anomalias de tempo de reflexão imediatamente após a ocorrência de um erro crasso (*blunder*).
- Identifica padrões de aceleração precipitada de lances seguidos de degradação cumulativa de precisão, gerando alertas didáticos para interromper a espiral de derrotas.

### 4.13 Treinador de Repertório com Algoritmo SuperMemo SM-2
- Sistema de fixação de variantes teóricas de abertura através de intervalos espaçados matematicamente calculados.
- Cada linha de abertura possui um Fator de Facilidade ($EF$), inicializado em 2.5 e ajustado a cada revisão conforme a resposta do usuário (qualidade $q \in [0, 5]$):

$$EF' = \max\left(1.3, \; EF + (0.1 - (5 - q) \cdot (0.08 + (5 - q) \cdot 0.02))\right)$$

- Cálculo do intervalo de revisão em dias ($I$):
  - $I(1) = 1$ dia
  - $I(2) = 6$ dias
  - $I(n) = \text{round}(I(n-1) \cdot EF)$ para $n \ge 3$
- Em caso de erro do usuário ($q < 3$), o ciclo é imediatamente reiniciado ($I=1, \text{repeticoes}=0$).

### 4.14 Explorador de Aberturas ECO
- Catálogo canônico categorizado pela classificação internacional ECO (Encyclopaedia of Chess Openings), incluindo variantes estruturadas:
  - **C50:** Abertura Italiana.
  - **C65:** Ruy Lopez (Abertura Espanhola).
  - **B90:** Defesa Siciliana (Variante Najdorf).
  - **D35:** Gambito da Dama Declinado.
  - **E60:** Defesa India do Rei.
- Exibição de estatísticas consolidadas de vitórias das Brancas, empates e vitórias das Negras em partidas de grandes mestres para cada lance candidato.

### 4.15 Gerenciador de Torneios Sistema Suíço FIDE & Integração Híbrida
- Módulo de emparceiramento estrito para competições presenciais e online:
  - Ordenação oficial da FIDE: 1º Pontuação $\rightarrow$ 2º Buchholz $\rightarrow$ 3º Rating Elo.
  - Proibição matemática absoluta de confrontos repetidos entre os mesmos jogadores.
  - Balanceamento rigoroso de atribuição de cores (Brancas e Negras) através do vetor `color_history`.
  - Gestão automática de *Bye* (1.0 ponto) em rodadas com número ímpar de participantes, com garantia de no máximo um *Bye* por competidor.
  - **Cálculo de Desempates em Tempo Real:** FFI nativa `chess_swiss_calculate_tiebreaks` que atualiza instantaneamente o índice Buchholz e Sonneborn-Berger a cada resultado registrado.
  - **Execução Híbrida de Partidas:** Cada confronto gerado na rodada pode ser disputado via:
    1. **Online P2P:** Sala multiplayer WebRTC direta sem servidor.
    2. **Tabuleiro Local (Pass & Play):** Tabuleiro interativo no dispositivo com relógio e nomes customizados.
    3. **Registro Manual:** Inserção direta de placares (`1-0`, `0-1`, `½-½`).
  - **Inscrição Dinâmica:** Botão de inscrição para cadastrar novos competidores locais ou remotos com nomes e ratings personalizados.
  - **Conformidade Visual:** Interface integrada ao `ThemeController.instance` com suporte pleno a temas Claro, Escuro e acentos cromáticos.

### 4.16 Auditoria Forense Estatística Anti-Cheat (Modelo Ken Regan)
- Ferramenta pericial fundamentada nas formulações do Professor Kenneth Regan (assessor da FIDE):
  - Cálculo da taxa de concordância de lances com a primeira opção do motor (*Stockfish Top-1 Agreement %*).
  - Cálculo da taxa de concordância com as duas primeiras opções (*Stockfish Top-2 Agreement %*).
  - Perda média de centipeões por lance (*Average Centipawn Loss - ACL*).
  - Desvio padrão do tempo gasto por lance ($\sigma_t$).
  - Produção do *Cheat Probability Score (CPS)* com vereditos periciais categorizados: Limpo, Inconclusivo, Suspeito ou Altamente Anômalo.

### 4.17 Banco de Dados Compactado com Zstandard
- Codificação binária compacta de partidas e posições táticas.
- Descompressão ultrarrápida com taxa de redução média de 9:1 em relação a bancos textuais em formato PGN.

### 4.18 Servidor Local Wi-Fi Cast
- Servidor HTTP e WebSocket embarcado na aplicação (`HttpServer.bind`), permitindo transmitir em tempo real o tabuleiro em HTML5 Canvas para qualquer navegador na rede local (Smart TVs, computadores ou projetores), sem necessidade de acesso à internet externa.

### 4.19 Sistema de Personalização Visual e Paletas de Cores
- **Modos de Tema da Interface:**
  - **Modo Noite Padrão (Dark Mode):** Superfícies em cinza carvão profundo (`#12161A` e `#1A222D`), texto de alto contraste e bordas sutis para longas sessões de estudo sem fadiga ocular.
  - **Modo Claro Padrão (Light Mode):** Superfícies claras e arejadas (`#F8FAFC` e `#FFFFFF`), tipografia nítida e contraste otimizado para ambientes externos ou iluminados.
- **8 Paletas Canônicas de Cores para o Tabuleiro:**
  1. **Torneio Verde:** Padrão clássico internacional FIDE (`#769656` nas casas escuras e `#EEEED2` nas casas claras).
  2. **Madeira Nobre:** Textura visual de carvalho suave e nogueira escura (`#B58863` / `#F0D9B5`).
  3. **Oceano Meia-Noite:** Tons navais profundos com gelo suave (`#34495E` / `#A9CCE3`).
  4. **Ametista Real:** Púrpura nobre combinada com lavanda aveludada (`#6C3483` / `#D7BDE2`).
  5. **Coral Pôr do Sol:** Terracota crepuscular e areia suave (`#BA4A00` / `#EDBB99`).
  6. **Cyber Onyx:** Estilo sci-fi minimalista com grafite e platina (`#2C3E50` / `#BDC3C7`).
  7. **Menta Pastel:** Verde sálvia contemporâneo e baunilha suave (`#48C9B0` / `#D1F2EB`).
  8. **Monocromático:** Estilo industrial de alto contraste com carvão fosco e branco neve (`#212121` / `#FAFAFA`).
- **5 Estilos de Cores para Peças:**
  1. **Staunton Clássico:** Peças brancas em marfim natural e negras em ébano/preto fosco.
  2. **Dourado e Prata:** Peças brancas com acabamento metálico em ouro nobre (`#F1C40F`) e negras em prata polida (`#BDC3C7`).
  3. **Cyber Neon:** Peças brancas em ciano elétrico luminescente (`#00F2FE`) e negras em magenta neon pulsante (`#FF007F`).
  4. **Marfim e Ébano Tradicional:** Marfim quente e madeira escura envelhecida.
  5. **Esmeralda e Ônix:** Brancas em verde esmeralda translúcido (`#2ECC71`) e negras em ônix profundo (`#1B2631`).
- **6 Cores de Destaque da Interface (Accent Swatches):**
  - Ciano Elétrico (`#00E5FF`), Verde Esmeralda (`#00E676`), Âmbar Dourado (`#FFD600`), Violeta Real (`#7C4DFF`), Carmesim (`#FF1744`) e Azul Royal (`#2979FF`).
- **Arquitetura Reativa de Temas:**
  - Implementado através do singleton central `ThemeController.instance` baseado em `ChangeNotifier`.
  - Propagação instantânea e atômica para todos os widgets sem necessidade de reinicializar a árvore de visualização ou recarregar rotas.
  - Tela de personalização visual com tabuleiro interativo em tempo real (*Live Preview*) permitindo testar lances e avaliar harmonização de paletas antes da aplicação global.

### 4.20 Multiplayer Online P2P & Borda Serverless (Custo Zero)
- **Topologia Híbrida WebRTC + Cloudflare Workers:**
  - **Tier 1 (P2P Direto):** Estabelece canal de dados ponto a ponto (`RTCDataChannel`) diretamente entre os dispositivos dos jogadores utilizando servidores STUN públicos e gratuitos do Google (`stun:stun.l.google.com:19302`), com latência típica de 10 a 25 ms.
  - **Tier 2 (Relay Serverless):** Caso os nós estejam sob roteadores com Symmetric NAT / CGNAT estrito, o sistema migra transparentemente para relay WebSocket em Cloudflare Workers rodando na borda sob a cota gratuita de 100.000 requisições diárias.
  - **Custo de Hospedagem:** R$ 0,00 perpétuo, sem infraestrutura dedicada nem mensalidades de servidores.
- **Protocolo de Rede Nativo em Rust (`network_protocol.rs`):**
  - **Validação Bidirecional:** Todo lance recebido é recalculado e validado pelo motor Bitboard local antes de ser aceito, impedindo injeções de lances ilegais.
  - **Compensação de Lag SNTP (RFC 4330):** Algoritmo de quatro marcas temporais ($t_0, t_1, t_2, t_3$) com cálculo de Round-Trip Time ($RTT$) e deriva temporal ($\theta$), concedendo crédito de atraso de até 200 ms sem permitir manipulação maliciosa de relógio.
  - **Emparelhamento Simplificado:** Salas efêmeras identificadas por códigos alfanuméricos de 6 caracteres (ex: `K9W2B4`) com compartilhamento de 1 clique via WhatsApp ou área de transferência.

### 4.21 Central de Ajuda & Guia do Usuário chessD
- Tela dedicada acessível pela barra superior ou pelo hub principal (`help_support_screen.dart`).
- **Manual de Regras Oficiais FIDE:** Regras completas de Roque Maior e Menor, Captura En Passant, Promoção de Peões e critérios de empate (afogamento, insuficiência material, repetição tripla e regra dos 50 lances).
- **FAQ e Solução de Problemas:** Instruções passo a passo sobre o multiplayer P2P, reconexão de partidas em redes móveis e auditoria forense anti-cheat.

---

## 5. Garantia de Qualidade e Cobertura de Testes

O projeto adota uma política de tolerância zero a falhas silenciosas (*silent bugs*), vazamentos de recursos e quebras de dimensionamento visual (*layout overflows*).

### Resumo dos Testes Automatizados

```
+-------------------------------------------------------------+
| Suite de Testes            | Testes Executados | Status     |
+----------------------------+-------------------+------------+
| Rust Core Unit & Property  | 38                | 38 Aprovados|
| Flutter Integration & UI   | 53                | 53 Aprovados|
| TOTAL                      | 91                | 91 Aprovados|
+----------------------------+-------------------+------------+
Tempo total de execucao dos 91 testes: < 12 segundos.
```

Principais cenários cobertos:
- Detecção de xeque-mate Pastor e Louco (*Fool's Mate*).
- Validação estrita de empate por afogamento (*Stalemate*).
- Validação de promoção com seleção de peça e captura *en passant*.
- Preservação da regra de bispos em cores opostas e rei entre as torres nas 960 posições Fischer Random.
- Resistência a ciclos infinitos e estabilidade do fator de facilidade no algoritmo SM-2.
- Verificação de não repetição de oponentes, alocação correta de *Bye* e cálculo exato de Buchholz no Sistema Suíço.
- Ciclo de vida de torneios híbridos com emparceiramento, opções de jogo local/online e inscrição dinâmica de competidores.
- Detecção de anomalias estatísticas pelo modelo de auditoria Ken Regan.
- Alternância dinâmica entre Modo Claro e Modo Noite e integridade reativa do `ThemeController`.
- Validação das 8 paletas de tabuleiro, 5 estilos de peças e 6 acentos cromáticos sem overflow visual.
- Ciclo de vida da sala P2P multiplayer, geração de códigos de 6 dígitos e validação de lances remotos com compensação SNTP.
- Renderização integral da Central de Ajuda com todas as seções e FAQ sem quebra de layout.
- Renderização limpa de todas as 18 telas e recursos do hub em resoluções mobile e desktop.

---

## 6. Estrutura do Repositório

```
chessD/
|-- .github/
|   `-- workflows/
|       `-- build-and-release.yml   # CI/CD automatizado para Windows e Android
|-- android/                        # Projeto Android nativo configurado
|-- lib/
|   |-- main.dart                   # Hub principal com todos os 18 recursos e modos
|   |-- services/
|   |   |-- app_update_service.dart      # Verificacao OTA via GitHub Releases
|   |   |-- chess_rust_ffi.dart          # Conector C-ABI FFI de baixo overhead
|   |   |-- p2p_multiplayer_service.dart # Gerenciador de partidas online P2P e SNTP
|   |   |-- player_stats_service.dart    # Persistencia JSON real de Elo, trilha e partidas
|   |   |-- system_bridge.dart           # Canal nativo Android/Desktop (URL Intent & Notificacoes)
|   |   |-- user_mistakes_service.dart   # Registro real de gafes para Treino de Erros
|   |   `-- wifi_cast_server.dart        # Servidor HTTP local de espelhamento
|   `-- ui/
|       |-- core/
|       |   |-- chess_theme.dart         # ThemeController, 8 paletas de tabuleiro, 5 de pecas, 6 acentos
|       |   `-- trail_connector.dart     # Curvas senoidais continuas em CustomPainter
|       |-- features/
|       |   |-- analysis/                # Telas de Revisao CAPS2 e Auditoria Anti-Cheat
|       |   |-- board/                   # Widget de Tabuleiro reativo com preview e Notacao
|       |   |-- game/                    # Modos Pass&Play, Batalha com Bots e Studio
|       |   |-- learning/                # Trilha de Maestria Gamificada (7 Modulos)
|       |   |-- multiplayer/        # Tela de Partida Online P2P e Lobby
|       |   |-- openings/           # Explorador Canonico de Aberturas ECO
|       |   |-- puzzles/            # Puzzles Infinitos e Puzzle Ladder
|       |   |-- repertoire/         # Treinador de Repertorio SuperMemo SM-2
|       |   |-- settings/           # Gerenciador de Acervo, Cast, Customizacao Visual e Ajuda
|       |   |-- tournament/         # Gerenciador de Torneio Suico FIDE
|       |   `-- training/           # Repeticao de Erros e Treino de Coordenadas
|       `-- theme/                  # Tokens visuais Dark Glass e Light responsivos
|-- rust_core/                      # Nucleo de Alta Performance em Rust
|   |-- Cargo.toml                  # Configuracao de dependencias Rust
|   `-- src/
|       |-- lib.rs                  # Exportacoes da biblioteca
|       |-- ffi.rs                  # Assinaturas extern "C" e manipulacao de ponteiros
|       |-- engine.rs               # Bitboards e validador de regras FIDE
|       |-- bot.rs                  # Motor Minimax e Alpha-Beta Pruning
|       |-- chess960.rs             # Gerador deterministico Fischer Random
|       |-- bitboard_heatmap.rs     # Mapas de tensao e controle territorial
|       |-- rating.rs               # Sistema de vidas, streaks e calculo de rating
|       |-- game_review.rs          # Algoritmo CAPS2 e analise de Tilt
|       |-- network_protocol.rs     # Protocolo P2P, SNTP de 4 tempos e validacao remota
|       |-- srs.rs                  # Repeticao espacada SuperMemo SM-2
|       |-- openings.rs             # Dicionario de aberturas e percentuais mestres
|       |-- tournament.rs           # Emparelhamentos Suico FIDE e tiebreaks
|       |-- anti_cheat.rs           # Pericia forense estatistica (Ken Regan)
|       `-- zstd_store.rs           # Compressao e serializacao Zstandard
|-- serverless/
|   `-- cloudflare-worker/
|       |-- worker.js               # Signaling WebRTC e WebSocket Relay Custo Zero
|       `-- wrangler.toml           # Configuracao para publicacao serverless
|-- scripts/
|   |-- build_windows.ps1           # Script PowerShell para compilacao Windows
|   `-- build_android.ps1           # Script PowerShell para compilacao Android
|-- test/                           # Bateria de testes automatizados Flutter (53 testes)
`-- README.md                       # Documentacao tecnica integral
```

---

## 7. Instruções de Compilação e Execução

### 7.1 Pré-Requisitos do Ambiente

- **Rust Toolchain:** 1.96 ou superior (`rustup default stable`).
- **Flutter SDK:** 3.47 ou superior (`channel stable`).
- **Para compilação Windows:** Visual Studio 2022 ou posterior com a carga de trabalho "Desenvolvimento para desktop com C++" instalada.
- **Para compilação Android:** Android SDK (API 34), Android NDK (versão 26.x) e utilitário `cargo-ndk`.

---

### 7.2 Compilação do Núcleo Nativo (Rust Core)

#### Para Windows Desktop:
```powershell
cd rust_core
cargo build --release
```
O artefato compilado estará disponível em `rust_core/target/release/rust_core.dll`.

#### Para Android (ABIs: arm64-v8a, armeabi-v7a, x86_64):
```bash
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

cd rust_core
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t x86_64 -o ../android/app/src/main/jniLibs build --release
```

---

### 7.3 Execução da Bateria de Testes

```powershell
# Testes do Motor Rust (31 testes aprovados)
cargo test --manifest-path rust_core/Cargo.toml

# Testes de Interface, Temas e Integracao Flutter (40 testes aprovados)
flutter test
```

---

### 7.4 Compilação do Executável Windows (.exe)

Para gerar o binário de distribuição para desktop:

```powershell
# 1. Compilar o aplicativo Windows
flutter build windows --release

# 2. Copiar a DLL Rust para a pasta do executavel
Copy-Item "rust_core\target\release\rust_core.dll" -Destination "build\windows\x64\runner\Release\rust_core.dll" -Force

# 3. Compactar para distribuicao portatil
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "build\chessD-v1.0.1-windows-x64.zip" -Force
```

O executável estará pronto para uso imediato em:
`build/windows/x64/runner/Release/chessD.exe`

---

### 7.5 Compilação do Pacote Android (.apk)

Com as bibliotecas `.so` geradas em `android/app/src/main/jniLibs/` e o Android SDK configurado no ambiente:

```bash
flutter build apk --release
```

O arquivo gerado estará localizado em:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 8. Notas de Lançamento (Releases)

Todas as versões binárias compiladas, pacotes de instalação e notas técnicas estão disponíveis na central oficial de distribuição:
[Acessar Central de Releases no GitHub](https://github.com/derbitr/chessD/releases)

### 8.1 Release v1.0.5 - [Ver Release v1.0.5 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.5)

#### Destaques da Versao v1.0.5:
- **Correcao Integral das Notificacoes de Atualizacao OTA (Android e Windows):** Adicao da permissao `INTERNET`, `ACCESS_NETWORK_STATE` e `POST_NOTIFICATIONS` no `AndroidManifest.xml` de producao (que anteriormente bloqueavam qualquer checagem HTTP na versao Release do Android).
- **Notificacao Nativa na Barra do Telefone & Abertura Direta de Download:** Novo canal nativo Android (`MainActivity.kt` + `SystemBridge`) exibindo alerta real no sistema operacional com abertura direta via `Intent.ACTION_VIEW` ao tocar na notificacao ou em "Baixar Agora".
- **Indicador Persistente Multi-Aba & Feedback Honesto de Rede:** Novo icone de notificacao com badge no topo da AppBar em todas as abas, SnackBar de alerta imediato, badge na aba Mais e fallback automatico via redirecionamento HTTP (`/releases/latest`) caso a API REST do GitHub sofra limite de taxa (403/429).
- **Qualidade e Estabilidade:** 91/91 testes automatizados aprovados (38 Rust + 53 Flutter, incluindo servidor HTTP local de testes OTA) e `flutter analyze` sem avisos.

#### Artefatos Disponiveis e Somas de Verificacao (v1.0.5):

| Artefato | Plataforma | Descricao | SHA-256 |
| :--- | :--- | :--- | :--- |
| [`chessD-v1.0.5-windows-x64.zip`](https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-windows-x64.zip) | Windows 64-bit | Pacote portatil contendo `chessD.exe`, `rust_core.dll`, `flutter_windows.dll` e dados de execucao | `E967ED1CCFB0C4356A7EEB4D9EE517881171A155C45F2DE1F87B52F7D8E0BFC4` |
| [`chessD-v1.0.5-android.apk`](https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-android.apk) | Android 8.0+ | Pacote de instalacao APK multi-ABI (`arm64-v8a`, `armeabi-v7a`, `x86_64`) compilado via GitHub Actions | `0915CF2935C735C8E88EEE826E73B452990E69DBA95F10C8B5C23401CD3FE8AA` |

---

### 8.2 Release v1.0.4 - [Ver Release v1.0.4 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.4)

#### Destaques da Versao v1.0.4:
- **Identidade Visual Unificada Chess.com:** Substituicao de tons ciano/teal residuais pela paleta verde e grafite canonica (#81B64C / #262522 / #2B2927) e troca de caracteres tipograficos de peao por icones vetoriais `PawnLogo` em pass-and-play e torneios.
- **Trilha de Quebra-Cabecas em 40 Marcos:** A aba Problemas agora exibe uma trilha de aventura com 40 nos organizados em 5 estagios tematicos conectados por curvas senoidais continuas (`TrailConnectorSegment`) e botoes chanfrados, integrada diretamente ao progresso em `InfinitePuzzlesScreen`.
- **Trilha de Maestria Expandida (7 Modulos):** Remocao de referencias ao termo Duolingo no titulo e na central de ajuda, ampliacao para 7 modulos completos com FENs e solucoes validadas em FFI nativo e reset automatico do tabuleiro ao errar lances.
- **Zero Dados Ficticios (Stats Reais & Treino de Erros Proprios):** Estatisticas da tela inicial (`0 resolvidos`, historico de partidas vazio, Elo inicial real) e `RetryMistakesScreen` (`0 / 0`, "Nenhum Erro Registrado!") agora refletem apenas acoes e erros reais persistidos em JSON (`PlayerStatsService` e `UserMistakesService`).
- **Qualidade e Estabilidade:** 86/86 testes automatizados aprovados (38 Rust + 48 Flutter) e `flutter analyze` sem avisos.

#### Artefatos Disponiveis e Somas de Verificacao (v1.0.4):

| Artefato | Plataforma | Descricao | SHA-256 |
| :--- | :--- | :--- | :--- |
| [`chessD-v1.0.4-windows-x64.zip`](https://github.com/derbitr/chessD/releases/download/v1.0.4/chessD-v1.0.4-windows-x64.zip) | Windows 64-bit | Pacote portatil contendo `chessD.exe`, `rust_core.dll`, `flutter_windows.dll` e dados de execucao | `B145434A02D8967F15CBD6585B79883EC8666143591FD29CDE37907919B5E69E` |
| [`chessD-v1.0.4-android.apk`](https://github.com/derbitr/chessD/releases/download/v1.0.4/chessD-v1.0.4-android.apk) | Android 8.0+ | Pacote de instalacao APK multi-ABI (`arm64-v8a`, `armeabi-v7a`, `x86_64`) compilado via GitHub Actions | `8C5C48E10D27490D1AF44A5FD670A983667A009CEB148822D2F9C753B907501A` |

---

### 8.3 Release v1.0.3 - [Ver Release v1.0.3 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.3)

#### Destaques da Versao v1.0.3:
- **Redesign Visual Canonico Inspirado no Chess.com:** Layout mobile com BottomNavigationBar de 5 abas (Inicio, Problemas, Aprender, Assistir, Mais), cards panoramicos de alta fidelidade e botao hero Verde FIDE (#81B64C).
- **Tokens Espectrais do Dossie RPA 10 (Dark Slate):** Implementacao de paleta escura (#262522, #2B2927, #383634, #413D3B) com tipografia de alto contraste (#F7F7F6) e legibilidade otimizada.
- **Logotipo Vetorial do Peao Integrado:** Novo PawnLogo com badge de status aplicado na AppBar, nos dialogos de sistema e nos seletores de navegacao.
- **Segmentacao de Torneios por Elo & Bots no Swiss Pairing:** Sistema de torneios com tres faixas de Elo (Iniciante 300-800, Intermediario 800-1500, Avancado 1500+). Eliminacao de bots de alto nivel em categorias de entrada e suporte a disputa direta contra bots ao clicar em partidas em andamento.
- **Bot Studio com Presets Calibrados e Baloes de Dialogo:** Inclusao de novos bots com personalidades distintas (Marko 300, Jamie 650, Luna 1000, Troy 1300, TJ 1800) e baloes de fala dinamicos.
- **Servico de Notificacao e Verificacao OTA (AppUpdateService):** Verificacao automatica e silenciosa de novas releases do GitHub Releases, com baloes de aviso interativos no topo da aba Inicio e checagem manual na aba Mais.
- **Estabilidade do Renderizador Desktop:** Desativacao explicita de renderizadores instaveis no Windows runner, assegurando inicializacao imediata e estavel via Skia sem falhas de tela preta.

#### Artefatos Disponiveis e Somas de Verificacao (v1.0.3):

| Artefato | Plataforma | Descricao | SHA-256 |
| :--- | :--- | :--- | :--- |
| [`chessD-v1.0.3-windows-x64.zip`](https://github.com/derbitr/chessD/releases/download/v1.0.3/chessD-v1.0.3-windows-x64.zip) | Windows 64-bit | Pacote portatil contendo `chessD.exe`, `rust_core.dll`, `flutter_windows.dll` e dados de execucao | `D1A10429D634823554404545D1D3908416B348D806B1B1DCD6C904BBB5EDF742` |
| [`chessD-v1.0.3-android.apk`](https://github.com/derbitr/chessD/releases/download/v1.0.3/chessD-v1.0.3-android.apk) | Android 8.0+ | Pacote de instalacao APK para dispositivos moveis (ABIs: arm64-v8a, armeabi-v7a e x86_64) | `C0CB546DC5F4AFC27B8D0F72711FFE73E3432C90EAE07E5D1D2B1B28FC4C3414` |

---

### 8.4 Release v1.0.2 - [Ver Release v1.0.2 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.2)

#### Destaques da Versão v1.0.2:
- **Multiplayer Online P2P com Custo Zero:** Arquitetura híbrida com canais diretos WebRTC (STUN Google) e sinalização em Cloudflare Workers (Edge Serverless gratuito). Partidas online em tempo real com latência reduzida e custo zero de hospedagem.
- **Protocolo de Rede e Algoritmo SNTP em Rust (`network_protocol.rs`):** Medição de RTT e offset temporal com compensação justa de lag até 200 ms e validação estrita de lances remotos por Bitboards FIDE.
- **Central de Ajuda & Guia do Usuário (`HelpSupportScreen`):** Seção completa com manual de regras oficiais FIDE (Roque, En Passant, Afogamento, 50 lances), guia de conectividade e FAQ.
- **Integração Completa do Sistema Suíço FIDE:** Pareamento estrito sem repetições, cálculo instantâneo de Buchholz/Sonneborn-Berger via FFI, opções de disputa via Multiplayer P2P ou Tabuleiro Local (Pass & Play) e inscrição aberta de competidores.
- **Saneamento Integral de Marca e Namespaces:** Pacote migrado para `chess_d`, namespace Android padronizado para `com.chessd.app` e expurgo de qualquer dependência de nomenclatura legada.
- **Expansão da Cobertura de Testes:** Bateria ampliada para 83 testes automatizados (38 testes de núcleo Rust e 45 testes de interface e rede Flutter), com 100% de aprovação e zero falhas de layout.

#### Artefatos Disponíveis e Somas de Verificação (v1.0.2):

| Artefato | Plataforma | Descrição | SHA-256 |
| :--- | :--- | :--- | :--- |
| [`chessD-v1.0.2-windows-x64.zip`](https://github.com/derbitr/chessD/releases/download/v1.0.2/chessD-v1.0.2-windows-x64.zip) | Windows 64-bit | Pacote portátil contendo `chessD.exe`, `rust_core.dll`, `flutter_windows.dll` e dados de execução | `F212AE891D66F2C3191EA9FC3878B80AEF7AB4ABC91B4457D9187B254C638620` |
| `chessD-v1.0.2-android.apk` | Android 8.0+ | Pacote de instalação APK para dispositivos móveis (ABIs: arm64-v8a, armeabi-v7a e x86_64) | [Disponível no GitHub Releases](https://github.com/derbitr/chessD/releases/tag/v1.0.2) |

---

### 8.5 Release v1.0.1 - [Ver Release v1.0.1 no GitHub](https://github.com/derbitr/chessD/releases/tag/v1.0.1)

#### Destaques da Versão v1.0.1:
- **Atualização Canônica de Marca:** Transição definitiva do nome do projeto e repositório para **chessD**.
- **Sistema Completo de Personalização Visual:** Alternância entre Modo Claro e Modo Noite padrão, 8 paletas de tabuleiro, 5 estilos de peças e 6 cores de acento.
- **Artefatos Históricos (v1.0.1):**
  - `chessD-v1.0.1-windows-x64.zip` (SHA-256: `8405862356B973EF37DC2F30E3E37C7215B17764498C663BD4EC0E949505E75E`)
  - `chessD-v1.0.1-android.apk` (SHA-256: `61FD25BB187B3BFBC74BCD5C5CAE5E8ACE65AC57162298F962168C5E46C45EED`)

---

### 8.6 Release v1.0.0 - Lançamento Inicial Canônico

#### Destaques da Versão v1.0.0:
- Implementação inicial completa de todas as 7 fases do plano mestre do motor de xadrez.
- Motor Bitboard FIDE 100% nativo em Rust eliminando qualquer necessidade de servidor externo.
- Revisão de partidas com precisão CAPS2, Detector de Tilt, Treinador SM-2, Sistema Suíço FIDE e Auditoria Anti-Cheat Ken Regan.

#### Artefatos Históricos (v1.0.0):

| Artefato | Plataforma | Descrição | SHA-256 |
| :--- | :--- | :--- | :--- |
| `chess-democratico-v1.0.0-windows-x64.zip` | Windows 64-bit | Pacote portátil v1.0.0 inicial | `EF64DE7DEE88BB5CDCC361F626629F6F51B3149CEB01C3FA2DE32913C04DBDCA` |
| `chess-democratico-v1.0.0-android.apk` | Android 8.0+ | Pacote de instalação APK v1.0.0 inicial | `1B486AE96174625D214F29E9171DD271B076140F826E074CBCF63F7206770A1C` |

---

### 8.7 Instruções de Instalação e Execução

#### No Windows:
1. Extraia o conteúdo do arquivo `.zip` da release em uma pasta de sua preferência.
2. Certifique-se de que o arquivo `rust_core.dll` permaneça na mesma pasta do executável `chessD.exe`.
3. Dê um duplo clique em `chessD.exe` para iniciar o aplicativo. Não é necessária nenhuma instalação adicional.

#### No Android:
1. Transfira o arquivo `.apk` da release para o armazenamento do seu smartphone ou faça o download diretamente pelo navegador do aparelho.
2. Abra o arquivo no gerenciador de arquivos do Android e permita a instalação a partir da fonte selecionada, se solicitado pelo sistema operacional.
3. Conclua a instalação e abra o aplicativo chessD. O aplicativo opera integralmente em modo offline desde a primeira inicialização.

---

## 9. Licença e Filosofia

Este projeto é disponibilizado sob os preceitos do software livre e de código aberto. Não contém telemetria oculta, não exige criação de contas de usuário e não depende de servidores remotos para nenhuma de suas funções principais.
