# Especificação de Design: chessD (Android)

**Data:** 13 de Outubro de 2026 (Atualizado em 07 de Novembro de 2026)  
**Status:** Definitivo, Aprovado & Hiper-Expandido (Arquitetura Suprema)  
**Alvo:** Android  
**Tecnologia Central:** **Flutter (UI / Apresentação) + Rust Core (Cérebro & Computação Nativa via `flutter_rust_bridge v2`)**  
**Repositório/Workspace:** `C:\Users\Breno\.gemini\antigravity\scratch\chess-app`  

---

## 1. Contexto e Motivação (The Why)

Plataformas consolidadas como o Chess.com construíram impérios comerciais baseados na retenção e monetização restritiva do aprendizado de xadrez: paywalls para quebra-cabeças ilimitados, limites em árvores de abertura, cobrança de assinaturas caras (como o plano Diamante) para acessar análises com engine, relatórios de fraquezas e ferramentas de estudo.

Este projeto estabelece o **Aplicativo de Xadrez Definitivo e chessD para Android**:
- **100% Gratuito e Livre de Paywalls:** Todas as ferramentas de elite liberadas sem restrição de vidas ou créditos.
- **100% Funcional Offline:** Funciona sem internet (avião, metrô, viagens), rodando motor neural e acervo no próprio dispositivo.
- **Arquitetura de Alta Performance:** Combinação da fluidez visual e gamificada do **Flutter** a 120 FPS com a segurança de memória e a velocidade computacional do **Rust**.

---

## 2. A Arquitetura Suprema: Flutter + Rust Core (`flutter_rust_bridge v2`)

Adotamos a divisão de responsabilidades mais robusta da engenharia móvel moderna:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       FLUTTER (Camada de Apresentação & UI)                 │
│  - Trilha gamificada estilo Duolingo com mapas verticais de nós             │
│  - Tabuleiro responsivo 120 FPS com interpolação de física suave (<120ms)   │
│  - Neuro-design (contraste 12:1, pop-out pré-atencional Treisman)           │
│  - Áudio ASMR de peças e relógio com vibração háptica tátil micro-calibrada │
│  - Widgets Android para a tela inicial (Home Screen Puzzle of the Day)      │
└──────────────────────────────────────▲──────────────────────────────────────┘
                                       │
                      flutter_rust_bridge v2 (Zero-Copy & Streams)
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                   RUST CORE (Cérebro, Engine & Infraestrutura)              │
│  - Motor Neural Stockfish NNUE & Shakmaty (regras, FEN/PGN e bitboards)     │
│  - ARM64 Neon SIMD com vetorização nativa e modulação térmica dinâmica      │
│  - Mapas de calor táticos (Heatmaps de controle) calculados em microssegundos│
│  - Descompactador Zstandard (4 milhões de puzzles em ~180MB binário 16-bit) │
│  - Treinador de Repertório de Aberturas por Repetição Espaçada (Anki SM-2)  │
│  - Scanner OCR Câmera-to-FEN (reconhecimento de diagramas físicos e telas)  │
│  - Coach Falado (TTS Offline) narrando lances e erros pedagogicamente       │
│  - Perícia Forense Anti-Cheat (análise estatística de precisão e tempo)     │
│  - Tabela de Finais Syzygy (bases matemáticas de finais perfeitos)          │
│  - Suporte a Tabuleiros Físicos Eletrônicos Bluetooth (DGT, Chessnut)       │
│  - Gerenciador de Torneios Offline (Sistema Suíço / Round-Robin)            │
│  - Multiplayer Local P2P Sockets (Bluetooth RFCOMM / Wi-Fi Direct)          │
│  - Banco de Dados Local Relacional Embutido (Rusqlite / Redb)               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Matriz Completa de Módulos & Funcionalidades

### 3.1. Trilha de Aprendizado Modular (Estilo Duolingo)
- **Mapa Vertical de Nós:** Progressão temática com nós interligados (Fundamentos, Táticas, Finais, Estratégia de Aberturas, Ataques ao Rei).
- **Lições Fechadas e Calibradas:** Texto teórico curto (1-2 minutos) acompanhado de bateria de 5 a 10 exercícios práticos com barra de progresso e avaliação por 1 a 3 estrelas.
- **Chefões Temáticos:** Duelos de final de módulo contra bots com estilo condizente com a matéria estudada.

### 3.2. Treino Tático Ilimitado & Escada de Problemas
- **Puzzles Infinitos Adaptativos:** Sem limite diário de exercícios, com algoritmo de rating (Glicko-2) ajustando a dificuldade conforme o nível do usuário.
- **Escada de Problemas (Puzzle Rush / Streak):** Modo sobrevivência e cronometrado (3 ou 5 minutos) com combo streak, feedback sonoro progressivo e loops dopaminérgicos.
- **Widget Android de Quebra-Cabeça Diário:** Resolva o problema do dia direto na tela inicial do celular sem abrir o app.

### 3.3. Motor Neural On-Device & Modos de Partida
- **Stockfish NNUE com Aceleração SIMD:** Cálculo de mais de 1.000.000 nós/segundo em ARM64 com modulação térmica (10-15ms para lances óbvios).
- **Calibração de Bots Humanizados (Elo 250 a 2800):** Injeção de imprecisões e atraso de reflexão humano.
- **Estúdio de Criação de Bots (Custom Bot Studio):** Crie e personalize seus próprios oponentes ajustando agressividade, taxas de sacrifício e repertório de abertura.
- **Xadrez 960 (Fischer Random) & Modo Às Cegas (Blindfold):** Sorteio de 960 posições iniciais e opção de peças invisíveis para cálculo mental.
- **Treinador de Coordenadas:** Mini-game contra o relógio para visualização rápida de casas.

### 3.4. Análise Profunda, Coach Falado & Forense
- **Revisão de Jogo com Gráfico Centipawn:** Avaliação completa de cada lance com cálculo de precisão global (*Accuracy %*).
- **Classificação Didática de Lances:** Brilhante (`!!`), Melhor Lance, Excelente, Imprecisão (`?!`), Erro (`?`), Gafe (`??`).
- **Coach Falado por IA (Áudio TTS & Texto em Português):** Explica verbalmente a lógica do erro (ex: *"Você perdeu a dama porque tirou a defesa da casa d1"*).
- **Detector de "Tilt" & Auditoria de Tempo:** Gráfico do tempo gasto por lance identificando lances no desespero (<0.8s) e congelamentos no relógio.
- **Forense Anti-Cheat Local:** Analisador estatístico que compara o histórico de partidas de um oponente contra profundidades da engine para detectar suspeitas de trapaça.

### 3.5. Ferramentas Avançadas de Estudo & Visão Computacional
- **Scanner de Tabuleiro por Câmera (Camera-to-FEN / OCR):** Aponte o celular para um livro ou tabuleiro físico e converta a posição em FEN instantaneamente.
- **Mapa de Calor Tático em Tempo Real (Rust Bitboards):** Camada visual indicando controle de casas, peças desprotegidas e linhas de raio-X calculada em microssegundos.
- **Treinador de Repertório por Repetição Espaçada (SRS / Anki SM-2):** Memorização de árvores de abertura com revisões programadas a cada 1, 3, 7 e 14 dias.
- **Explorador de Aberturas Ilimitado (Polyglot / ECO):** Árvore com variantes profundas, porcentagens de vitória e respostas dos mestres.
- **Treinar os Próprios Erros ("Retry Mistakes"):** Geração automática de desafios táticos a partir das gafes reais cometidas pelo usuário.
- **Modo "Mestre por um Dia" (Guess the Move):** Adivinhe o lance de partidas históricas (Fischer, Kasparov, Tal) com pontuação de estilo.
- **Treinador de Finais Teóricos & Bases Syzygy:** Posições obrigatórias (Lucena, Philidor, oposição) com resolução matemática precisa de finais elementares.
- **Importador de Jogos (Chess.com / Lichess PGN):** Sincronização direta por usuário ou colar PGN para análise gratuita.

### 3.6. Conectividade chessD & Integração com Hardware
- **Modo Pass & Play:** Tabuleiro espelhado com relógio tátil duplo para dois jogadores no mesmo smartphone.
- **Multiplayer P2P Local (Sem Internet):** Conexão via Bluetooth RFCOMM / Wi-Fi Direct para disputas entre aparelhos próximos sem necessidade de servidor.
- **Integração com Tabuleiros Físicos Eletrônicos (Smart Boards):** Conexão Bluetooth com tabuleiros físicos (DGT Pegasus, Chessnut Air, Millennium) para jogar fisicamente e analisar no app.
- **Gerenciador de Torneios Offline:** Organizador de campeonatos locais (Sistema Suíço / Round-Robin) com emparceiramento e critérios de desempate automáticos.
- **Espelhamento Web Local (Wi-Fi Cast):** Servidor HTTP leve embutido no celular para projetar o tabuleiro ao vivo na Smart TV ou no navegador do notebook.
- **Card de Resumo Compartilhável:** Exportação de imagens elegantes com gráficos de precisão e lances brilhantes para WhatsApp e Instagram.

---

## 4. Diretrizes de Design, Neurociência & Engenharia de Áudio

- **`frontend-design`:** Paleta tecnológica Dark Obsidian (`#0B0F17`), ardósia (`#151C28`), acento ciano elétrico (`#00E5FF`) e carmesim neon (`#FF1744`). Zero estética genérica de IA.
- **`neuro-conversion-science`:** Contraste superior a 12:1 contra fadiga ocular, pop-out pré-atencional Treisman em lances críticos e botões principais posicionados nos 40% inferiores da tela (ergonomia do polegar).
- **`animate`:** Filosofia de Emil Kowalski com peças movendo em <120ms na física de mola rápida e orçamentos de celebração elástica para 3 estrelas na trilha.
- **Engenharia de Áudio ASMR:** Sons estéreo de peças de madeira maciça Staunton em tabuleiros nobres, cliques mecânicos de relógio de torneio e respostas de vibração háptica tátil.

---

## 5. Garantia de Qualidade & Confiabilidade

- **Test-Driven Development (TDD):** A Lei de Ferro se aplica tanto ao código Rust quanto ao Dart. Nenhum componente crítico (gerador de lances, FEN parser, algoritmo SM-2, bitboards) é aceito sem teste falho prévio.
- **Systematic Debugging:** Diagnóstico metódico em 4 etapas para investigar causas-raiz antes de qualquer alteração de código.
