# Soberano Chess

Plataforma autônoma de xadrez, estudo tático gamificado e perícia analítica de partidas, desenvolvida com Flutter 3.47 e Rust 1.96. Totalmente offline, soberana e sem cobrança por recursos analíticos.

---

## 1. Visão Geral do Projeto

O Soberano Chess é um aplicativo de xadrez de alta performance projetado sob o princípio da soberania digital do usuário. Ao contrário de plataformas comerciais baseadas em assinaturas recorrentes (como as modalidades Platinum e Diamond de plataformas online), o Soberano Chess executa 100% das suas rotinas de validação de regras FIDE, geração de lances, busca minimax, árvores de abertura, repetição espaçada e cálculo de precisão algorítmica diretamente no dispositivo do usuário, sem emitir telemetria nem demandar conexão com a internet.

A infraestrutura foi construída combinando a expressividade e fluidez gráfica do Flutter (renderização a 120 FPS com suporte a gestos e temas de alto contraste) com a segurança de memória, determinismo e velocidade do Rust compilado para código nativo de máquina via Foreign Function Interface (FFI).

---

## 2. Comparativo de Recursos: Soberano Chess vs. Plataformas Comerciais

| Funcionalidade | Plataformas Comerciais (Plano Gratuito) | Plataformas Comerciais (Diamond / \$120+/ano) | Soberano Chess (100% Gratuito e Livre) |
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
- 8 patamares distintos de dificuldade cobrindo faixas de Elo de 400 a 2400.
- 3 perfis de personalidade técnica:
  - **Classica:** Busca equilibrada entre solidez posicional e segurança de rei.
  - **Agressiva:** Ponderação inflacionada para linhas abertas, sacrifícios e lances ofensivos.
  - **Posicional:** Foco estrito em estrutura de peões, postos avançados e controle do centro.
- Motor Minimax com poda Alfa-Beta e *Quiescence Search* para mitigar o efeito horizonte.

### 4.6 Bot Studio
- Estação de customização onde o usuário pode criar e calibrar seus próprios oponentes sintéticos, ajustando parâmetros de profundidade de busca, tolerância a riscos e estilo de jogo.

### 4.7 Fischer Random Chess960
- Geração determinística dos 960 arranjos iniciais oficiais propostos pelo Grande Mestre Bobby Fischer.
- Garantia de bispos em casas de cores alternadas e rei confinado entre as duas torres.
- Navegação por semente numérica (0 a 959), onde o índice 518 corresponde rigorosamente à posição clássica do xadrez tradicional.

### 4.8 Mapas de Calor Tático (Bitboard Heatmaps)
- Mapeamento em tempo real do controle territorial e da tensão de ataque sobre cada casa.
- Sobreposição gráfica translúcida indicando zonas de pressão mútua e fraquezas estruturais.

### 4.9 Trilha Gamificada de Aprendizado (Estilo Duolingo)
- Currículo pedagógico estruturado em seções progressivas:
  1. Fundamentos e Movimento das Peças.
  2. Táticas Essenciais (Garfos, Cravadas, Espetos e Descobertas).
  3. Finais Básicos e Estrutura de Peões.
  4. Mestria Posicional e Profilaxia.
- Visualização em nós interconectados por curvas senoidais, bloqueio de módulos dependentes e premiação de até 3 estrelas por lição concluída.

### 4.10 Puzzles Táticos Infinitos e Puzzle Ladder
- Modo contínuo com geração sob demanda a partir de banco compactado.
- Sistema competitivo *Puzzle Ladder* com 3 vidas (strikes), bônus de pontuação por sequência consecutiva de acertos (*streak multiplier*) e atualização dinâmica de Elo tático.

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

### 4.15 Gerenciador de Torneios Sistema Suíço FIDE
- Módulo de emparceiramento estrito para torneios presenciais:
  - Ordenação por pontuação acumulada e desempates.
  - Proibição absoluta de confrontos repetidos entre os mesmos jogadores.
  - Balanceamento de atribuição de cores (Brancas e Negras).
  - Gestão automática de *Bye* (1.0 ponto) em rodadas com número ímpar de participantes.
  - Cálculo oficial dos critérios de desempate Buchholz e Sonneborn-Berger.

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

---

## 5. Garantia de Qualidade e Cobertura de Testes

O projeto adota uma política de tolerância zero a falhas silenciosas (*silent bugs*), vazamentos de recursos e quebras de dimensionamento visual (*layout overflows*).

### Resumo dos Testes Automatizados

```
+-------------------------------------------------------------+
| Suite de Testes            | Testes Executados | Status     |
+----------------------------+-------------------+------------+
| Rust Core Unit & Property  | 31                | 31 Aprovados|
| Flutter Integration & UI   | 34                | 34 Aprovados|
| TOTAL                      | 65                | 65 Aprovados|
+----------------------------+-------------------+------------+
Tempo total de execucao dos 65 testes: < 9 segundos.
```

Principais cenários cobertos:
- Detecção de xeque-mate Pastor e Louco (*Fool's Mate*).
- Validação estrita de empate por afogamento (*Stalemate*).
- Validação de promoção com seleção de peça e captura *en passant*.
- Preservação da regra de bispos em cores opostas e rei entre as torres nas 960 posições Fischer Random.
- Resistência a ciclos infinitos e estabilidade do fator de facilidade no algoritmo SM-2.
- Verificação de não repetição de oponentes e alocação correta de *Bye* no Sistema Suíço.
- Detecção de anomalias estatísticas pelo modelo de auditoria Ken Regan.
- Renderização limpa de todas as 15 telas do app em resoluções mobile e desktop.

---

## 6. Estrutura do Repositório

```
chess-app/
|-- .github/
|   `-- workflows/
|       `-- build-and-release.yml   # CI/CD automatizado para Windows e Android
|-- android/                        # Projeto Android nativo configurado
|-- lib/
|   |-- main.dart                   # Hub principal com todos os 15 modos
|   |-- services/
|   |   |-- chess_rust_ffi.dart     # Conector C-ABI FFI de baixo overhead
|   |   `-- wifi_cast_server.dart   # Servidor HTTP local de espelhamento
|   `-- ui/
|       |-- features/
|       |   |-- analysis/           # Telas de Revisao CAPS2 e Auditoria Anti-Cheat
|       |   |-- board/              # Widget de Tabuleiro e Notacao
|       |   |-- game/               # Modos Pass&Play, Batalha com Bots e Studio
|       |   |-- learning/           # Trilha Gamificada Duolingo
|       |   |-- openings/           # Explorador Canônico de Aberturas ECO
|       |   |-- puzzles/            # Puzzles Infinitos e Puzzle Ladder
|       |   |-- repertoire/         # Treinador de Repertorio SuperMemo SM-2
|       |   |-- settings/           # Gerenciador de Acervo Offline e Cast
|       |   |-- tournament/         # Gerenciador de Torneio Suico FIDE
|       |   `-- training/           # Repeticao de Erros e Treino de Coordenadas
|       `-- theme/                  # Paleta Dark Glass responsiva
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
|       |-- srs.rs                  # Repeticao espacada SuperMemo SM-2
|       |-- openings.rs             # Dicionario de aberturas e percentuais mestres
|       |-- tournament.rs           # Emparelhamentos Suico FIDE e tiebreaks
|       |-- anti_cheat.rs           # Pericia forense estatistica (Ken Regan)
|       `-- zstd_store.rs           # Compressao e serializacao Zstandard
|-- scripts/
|   |-- build_windows.ps1           # Script PowerShell para compilacao Windows
|   `-- build_android.ps1           # Script PowerShell para compilacao Android
|-- test/                           # Bateria de testes automatizados Flutter
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
# Testes do Motor Rust
cargo test --manifest-path rust_core/Cargo.toml

# Testes de Interface e Integracao Flutter
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
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "build\soberano-chess-v1.0.0-windows-x64.zip" -Force
```

O executável estará pronto para uso imediato em:
`build/windows/x64/runner/Release/soberano_chess.exe`

---

### 7.5 Compilação do Pacote Android (.apk)

Com as bibliotecas `.so` geradas em `android/app/src/main/jniLibs/` e o Android SDK configurado no ambiente:

```bash
flutter build apk --release
```

O arquivo gerado estará localizado em:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 8. Notas de Lançamento da Primeira Versão (Release v1.0.0)

### 8.1 Destaques do Lançamento
- **Lançamento Inicial Canônico (v1.0.0):** Implementação completa de todas as 7 fases planejadas no plano mestre do projeto.
- **Autonomia Absoluta:** Motor Bitboard 100% nativo em Rust eliminando qualquer necessidade de assinatura ou infraestrutura de terceiros.
- **Recursos Exclusivos:** Inclusão de recursos habitualmente bloqueados sob paywalls em outras plataformas, incluindo Análise CAPS2, Detector de Tilt Emocional, Treinador de Repertório SM-2, Sistema Suíço FIDE com tiebreaks e Perícia Anti-Cheat Ken Regan.

### 8.2 Artefatos Disponíveis e Somas de Verificação

| Artefato | Plataforma | Descrição | SHA-256 |
| :--- | :--- | :--- | :--- |
| `soberano-chess-v1.0.0-windows-x64.zip` | Windows 64-bit | Pacote portátil contendo `soberano_chess.exe`, `rust_core.dll`, `flutter_windows.dll` e dados de execução | `59819A6FAA6D89436154805CD57FD0EE8B79ACD7565997DEFAE8D6A5A65CF065` |
| `soberano-chess-v1.0.0-android.apk` | Android 8.0+ | Pacote de instalação APK para dispositivos móveis (gerado via pipeline de compilação com suporte a arm64-v8a e armeabi-v7a) | Verificado via GitHub Actions CI/CD |

### 8.3 Instruções de Instalação e Execução

#### No Windows:
1. Extraia o conteúdo de `soberano-chess-v1.0.0-windows-x64.zip` em uma pasta de sua preferência.
2. Certifique-se de que o arquivo `rust_core.dll` permaneça na mesma pasta do executável `soberano_chess.exe`.
3. Dê um duplo clique em `soberano_chess.exe` para iniciar o aplicativo. Não é necessária nenhuma instalação adicional.

#### No Android:
1. Transfira o arquivo `app-release.apk` para o armazenamento do seu smartphone ou faça o download diretamente pelo navegador do aparelho.
2. Abra o arquivo no gerenciador de arquivos do Android e permita a instalação a partir da fonte selecionada, se solicitado pelo sistema operacional.
3. Conclua a instalação e abra o aplicativo Soberano Chess. O aplicativo opera integralmente em modo offline desde a primeira inicialização.

---

## 9. Licença e Filosofia

Este projeto é disponibilizado sob os preceitos do software livre e soberano. Não contém telemetria oculta, não exige criação de contas de usuário e não depende de servidores remotos para nenhuma de suas funções principais.
