# Plano de Execução Detalhado: Aplicativo Mobile de Xadrez Soberano (Android)

**Data:** 13 de Outubro de 2026 (Atualizado em 07 de Novembro de 2026)  
**Documento de Design de Referência:** [`docs/superpowers/specs/2026-10-12-chess-mobile-app-design.md`](file:///C:/Users/Breno/.gemini/antigravity/scratch/chess-app/docs/superpowers/specs/2026-10-12-chess-mobile-app-design.md)  
**Workspace:** `C:\Users\Breno\.gemini\antigravity\scratch\chess-app`  
**Alvo:** Android (Flutter 3.x+ / Dart 3 + Rust Core via `flutter_rust_bridge v2`)

---

## Matriz de Habilidades & Ferramentas Integradas à Execução

| Categoria / Ferramenta | Papel Prático no Plano de Execução |
|---|---|
| **Arquitetura Híbrida** | `flutter_rust_bridge v2` gerando código tipado assíncrono e zero-copy entre Dart e Rust. |
| **Computação & Regras (Rust)** | `shakmaty`, `stockfish` NNUE SIMD, `zstd-rs`, bitboards 64-bit, `rusqlite` e `tokio`. |
| **Design Visual** | `frontend-design`: Paleta Dark Obsidian (`#0B0F17`), Slate (`#151C28`), Ciano Pop-Out (`#00E5FF`). |
| **Neurociência & Ergonomia** | `neuro-conversion-science`: Contraste >12:1, pop-out Treisman, ergonomia de polegar (zona 40% inferior). |
| **Física de Animação** | `animate`: Emil Kowalski bar (<120ms no tabuleiro, curvas de mola elásticas para celebrações). |
| **Arquitetura Flutter** | `flutter-apply-architecture-best-practices`: Camadas estritas UI / MVVM, Domain e Data. |
| **Layout Responsivo** | `flutter-build-responsive-layout`: Zero overflows em telas pequenas, dobráveis e tablets. |
| **Qualidade & Confiabilidade** | `test-driven-development` (TDD): A Lei de Ferro no Rust (`cargo test`) e no Flutter (`flutter test`). |
| **Diagnóstico de Bugs** | `systematic-debugging`: Investigação sistemática em 4 fases sem remendos superficiais. |

---

## Visão Geral das 7 Fases de Execução

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FASES DO PLANO DE EXECUÇÃO                         │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ Fase 1: Fundação, Rust Core & FRB v2 │ Fase 2: Design System, Zstd & Puzzles│
│ [flutter_rust_bridge, SIMD, TDD]     │ [frontend-design, neuro-science, ETL]│
│ - Setup Flutter Android NDK & Cargo  │ - Tokens de cores e contraste >12:1  │
│ - Rust Core: Shakmaty + Stockfish    │ - Extração taxonômica REA & lições IA│
│ - Modulação térmica & 120 FPS        │ - Super-compressão Zstandard 180MB   │
│ - Calibração de Bots (Elo 250-2800)  │ - Banco local SQLite com 20k puzzles │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ Fase 3: Tabuleiro, Modos & Heatmap   │ Fase 4: Trilha Duolingo & Treino     │
│ [animate, rust-bitboards, responsive]│ [neuro-science, animate, streak]     │
│ - Tabuleiro fluido 120 FPS (<120ms)  │ - Trilha vertical de nós (Duolingo)  │
│ - Mapa de Calor Tático (Bitboards)   │ - Puzzles Infinitos com rating       │
│ - Xadrez 960 & Modo Às Cegas         │ - Escada de Problemas (Rush/Streak)  │
│ - Treinador de Coordenadas           │ - Widget Android de Puzzle do Dia    │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ Fase 5: Análise, Coach & Forense     │ Fase 6: Módulos de Elite & Conexão   │
│ [frontend-design, TDD, TTS falado]   │ [TDD, SM-2, OCR Câmera, Bluetooth]  │
│ - Gráfico centipawn e precisão %     │ - Scanner Câmera-to-FEN (OCR)        │
│ - Coach falado por IA (Áudio TTS)    │ - Repetição Espaçada (Anki Aberturas)│
│ - Auditoria de Tempo & Detecção Tilt │ - Explorador de Aberturas ilimitado  │
│ - Perícia Forense Anti-Cheat         │ - Estúdio de Criação de Bots         │
│ - Card de Resumo Compartilhável      │ - Smartboards DGT & Torneios Suíços  │
│                                      │ - Pass & Play e P2P Bluetooth/Wi-Fi  │
├──────────────────────────────────────┴──────────────────────────────────────┤
│ Fase 7: Otimização Offline, Downloader 4M+ & Compilação do APK              │
│ [systematic-debugging, widget-test, release build]                          │
│ - Descompactador zstd em background e validação SHA-256                     │
│ - Servidor local de espelhamento Web (Wi-Fi Cast)                           │
│ - Testes de estresse de bateria, térmicos e compilação do APK de produção   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Fase 1: Fundação do Projeto, Rust Core Nativo & `flutter_rust_bridge v2`

**Skills & Tecnologias:** `flutter_rust_bridge`, `shakmaty`, `test-driven-development` (Cargo test + Flutter test)

### Tarefas
1. **Estruturação do Projeto Híbrido:**
   - Criar projeto Flutter Android (`com.soberano.chess`).
   - Configurar o crate de Rust em `rust/` integrado ao Android NDK via Cargo NDK e `flutter_rust_bridge_codegen`.
   - Compilação direcionada para `arm64-v8a` com flags de alta performance no `Cargo.toml` (`opt-level = 3`, `lto = true`, `codegen-units = 1`).
2. **Integração do Motor Stockfish & Regras em Rust:**
   - [TDD] Testes unitários em Rust validando geração de lances legais via `shakmaty`.
   - Ponte C++/Rust para o Stockfish NNUE nativo com suporte a comandos UCI assíncronos.
   - Geração de bindings automáticos via FRB v2 expondo funções assíncronas e streams para o Dart.
3. **Controle Térmico & Gestão de Profundidade:**
   - Implementação de lógica de profundidade dinâmica no Rust (profundidade 10-12 para lances instantâneos em 10ms; 16-20 para análises complexas).
4. **Calibrador de Bots Humanizados (Elo 250 a 2800):**
   - [TDD] Testes unitários para injeção de imprecisões e atraso humano de pensamento nos bots.

---

## Fase 2: Design System, Pipeline de Conteúdo Híbrido & Zstandard

**Skills:** `frontend-design`, `neuro-conversion-science`, `flutter-apply-architecture-best-practices`, `test-driven-development`

### Tarefas
1. **Design System & Tokens Visuais (`lib/ui/core/`):**
   - Implementar `AppColors` seguindo contraste mínimo de 12:1 (Dark Obsidian `#0B0F17`, Slate `#151C28`, Ciano Pop-Out `#00E5FF`, Carmesim Neon `#FF1744`).
   - Tipografia de escala proporcional legível em telas pequenas.
   - Variantes de tabuleiro (Verde Torneio, Nogal Nobre e Moderno Escuro).
2. **Arquitetura em Camadas (`flutter-apply-architecture-best-practices`):**
   - Divisão rigorosa: `lib/data/`, `lib/domain/`, `lib/ui/`.
3. **Mapeamento Taxonômico & Síntese Didática:**
   - Estruturação dos módulos da trilha via REA e redação dos textos didáticos originais por IA.
4. **Super-Compressão Zstandard & Banco Local (SQLite / Drift):**
   - [TDD] Módulo Rust com `zstd-rs` decodificando lances de 16-bits a partir de arquivos `.zst`.
   - Ingestão dos primeiros 20.000 quebra-cabeças e lições completas para funcionamento offline imediato.

---

## Fase 3: Tabuleiro Interativo, Gestos, Modos Especiais & Mapa de Calor

**Skills:** `animate`, `flutter-build-responsive-layout`, `rust-bitboards`, `test-driven-development`

### Tarefas
1. **Componente de Tabuleiro (`ChessBoardWidget`):**
   - [animate] Movimentação suave de peças (<120ms) com física de mola rápida e respeito a *reduced-motion*.
   - [flutter-build-responsive-layout] Proporção 8x8 responsiva sem *RenderFlex overflow*.
   - Gestos de toque, arrastar/soltar, pré-lances e modal de promoção.
2. **Mapa de Calor Tático em Tempo Real (Rust Bitboards):**
   - [Rust] Cálculo de bitboards de 64-bits avaliando controle de casas e peças desprotegidas em menos de 1 milissegundo.
   - [Flutter] Camada de sobreposição visual com gradiente translúcido de controle e linhas pontilhadas de raio-X.
3. **Xadrez 960 (Fischer Random) & Modo Às Cegas:**
   - [TDD] Gerador DGT de posições 0-959 em Rust e regras de roque 960.
   - Alternador de visibilidade de peças para treino mental.
4. **Treinador de Coordenadas:**
   - Mini-game com cronômetro de 30s e toques na zona de alcance do polegar.

---

## Fase 4: Gamificação, Trilha Duolingo & Modos de Treino

**Skills:** `neuro-conversion-science`, `animate`, `flutter-apply-architecture-best-practices`

### Tarefas
1. **Interface da Trilha Estilo Duolingo (`LearningTrackScreen`):**
   - [neuro-conversion-science] Mapa vertical de nós com feedback de progresso e ergonomia nos 40% inferiores da tela.
   - [animate] Micro-delight elástico na revelação de estrelas e desbloqueio de novas fases.
   - Batalha contra "Chefão" temático ao fim de cada módulo.
2. **Modo Quebra-Cabeças Infinitos (`InfinitePuzzlesScreen`):**
   - Rating Glicko-2 em Rust atualizado em tempo real.
   - Transição contínua sem telas de bloqueio ou anúncios.
3. **Modo Escada de Problemas (`PuzzleLadderScreen`):**
   - Mecânica dopaminérgica de sequência (combo streak) e som/vibração tátil progressiva.
   - Modos: 3 vidas ou cronômetro (3 ou 5 minutos) com recordes locais.
4. **Widget Android para Tela Inicial:**
   - AppWidget nativo exibindo o quebra-cabeça do dia diretamente na Home Screen do celular.

---

## Fase 5: Análise Profunda, Coach Falado (TTS), Tilt & Forense Anti-Cheat

**Skills:** `frontend-design`, `test-driven-development`, áudio nativo

### Tarefas
1. **Histórico Local & Gráfico Centipawn:**
   - Armazenamento SQLite de PGNs e gráfico de vantagem das Brancas vs. Pretas.
   - Classificação didática de lances: Brilhante (`!!`), Melhor Lance, Excelente, Imprecisão (`?!`), Erro (`?`), Gafe (`??`).
2. **Coach Falado por IA (Áudio TTS & Texto em Português):**
   - Síntese de voz local explicando verbalmente o motivo de cada gafe cometida.
3. **Auditoria de Gestão de Tempo & Detector de Tilt:**
   - Gráfico de segundos gastos por lance e detecção de padrões de nervosismo e lances em desespero.
4. **Perícia Forense Anti-Cheat:**
   - Analisador estatístico em Rust calculando índice de correlação contra a engine para auditar PGNs suspeitos de oponentes.
5. **Gerador de Cards Compartilháveis:**
   - Exportação de imagem elegante com resumo da partida e gráfico de precisão para redes sociais.

---

## Fase 6: Módulos de Elite, Visão Computacional & Conectividade Soberana

**Skills:** `test-driven-development`, `flutter-apply-architecture-best-practices`, Bluetooth / Sockets

### Tarefas
1. **Scanner de Tabuleiro por Câmera (Camera-to-FEN / OCR):**
   - Reconhecimento de peças em diagramas físicos/telas com visão computacional convertendo para FEN.
2. **Treinador de Repertório por Repetição Espaçada (SRS / Algoritmo SM-2):**
   - Algoritmo de memorização em Rust agendando revisões inteligentes de aberturas (1, 3, 7 e 14 dias).
3. **Explorador de Aberturas Ilimitado & Finais Teóricos:**
   - Árvore Polyglot profunda e treino prático de finais clássicos com bases Syzygy.
4. **Treino de Erros Próprios ("Retry Mistakes") & Modo Mestre por um Dia:**
   - Criação de quebra-cabeças das gafes do usuário e adivinhação de lances históricos de grandes mestres.
5. **Estúdio de Criação de Bots Personalizados:**
   - Customizador de estilo tático, agressividade e repertório de abertura.
6. **Gerenciador de Torneios Offline & Conectividade Local:**
   - Sistema Suíço / Round-Robin para organizar torneios sem internet.
   - Suporte Bluetooth a tabuleiros eletrônicos físicos (DGT Pegasus, Chessnut).
   - Modo Pass & Play com relógio duplo e Multiplayer Local P2P via Bluetooth/Wi-Fi Direct.

---

## Fase 7: Otimização Offline, Downloader dos 4M+ & Compilação do APK

**Skills:** `flutter-add-widget-test`, `systematic-debugging`, `android-cli`

### Tarefas
1. **Gerenciador de Downloads do Acervo Expandido:**
   - Downloader assíncrono em Rust para pacotes `.zst` com validação SHA-256 e descompactação em background.
2. **Servidor Local de Espelhamento Web (Wi-Fi Cast):**
   - Servidor HTTP leve para projetar o tabuleiro ao vivo na Smart TV ou no navegador do PC.
3. **Testes de Estresse & Otimização de Bateria:**
   - Teste de consumo térmico e execução de suite automatizada de testes (`cargo test` + `flutter test`).
4. **Build de Produção do APK:**
   - Compilação do executável final via `flutter build apk --release`.

---

## Ordem de Início Imediato

1. **Sprint 1 (Fase 1):** Scaffolding Flutter Android + crate Rust com `flutter_rust_bridge v2`, integrando `shakmaty` e Stockfish NNUE compilado para ARM64 Neon SIMD com testes TDD.
2. **Sprint 2 (Fase 2):** Design System em `lib/ui/core/`, banco SQLite de 20k puzzles e descompressão Zstandard em Rust.
3. **Sprint 3 (Fase 3 & 4):** Tabuleiro a 120 FPS (<120ms), Mapa de Calor Tático, Xadrez 960, Coordenadas, Trilha Duolingo e Widget Android.
4. **Sprint 4 (Fase 5 & 6):** Análise centipawn, Coach falado TTS, Detector de Tilt, Forense Anti-Cheat, Scanner OCR por Câmera, Treinador SRS de Aberturas, Smartboards DGT, Bot Studio e Torneios Suíços.
5. **Sprint 5 (Fase 7):** Downloader de pacotes zstd, Wi-Fi Cast e compilação do APK Android de produção.
