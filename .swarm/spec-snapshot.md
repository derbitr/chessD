# Spec: Aplicativo Mobile de Xadrez Soberano (Android)

Source of truth: docs/superpowers/specs/2026-10-12-chess-mobile-app-design.md (approved by user).

## Functional Requirements
- FR-001 [MUST] App Flutter Android-only (package com.soberano.chess); app shell + roteamento + state management (Riverpod) + DI funcionais antes de qualquer feature de UI.
- FR-002 [MUST] Engine Stockfish NNUE compilada on-device (C++ NDK, arm64-v8a) via bridges UCI/FFI assynchronos em dart:isolate; UI nunca bloqueia.
- FR-003 [MUST] Offline-first: trilha, lições, 20k puzzles embutidos, bots, histórico e análise 100% funcionais em modo avião.
- FR-004 [MUST] Zero paywalls механиción: nenhum limite diário, "vidas", recarga de energia ou bloqueio de análise.
- FR-005 [MUST] Trilha estilo Duolingo: lições fechadas com 5-10 exercícios, estrelas 1-3, desbloqueio sequencial e chefão por módulo.
- FR-006 [MUST] Quebra-cabeças infinitos com rating tático adaptativo, sem limite diário.
- FR-007 [MUST] Escada de problemas: modo sobrevivência (3 erros) ou cronometrado (3/5min) com combo streak e recordes locais.
- FR-008 [MUST] Bots Elo 250-2800 com personalidades (Agressivo/Posicional/Mestre Clássico), imprecisões humanizadas e hooks determinísticos p/ testes (seed, clock injetável, BOT_TEST_MODE).
- FR-009 [MUST] Histórico local completo + análise pós-jogo (gráfico centipawn, Accuracy %, classificação !!/melhor/excelente/?!/erro/??).
- FR-010 [MUST] Conteúdo clean-room: nenhum asset/código proprietário copiado; taxonomia mapeada + textos/exercícios originais.
- FR-011 [MUST] Pacotes de puzzles 4M+ baixáveis sob demanda (mirrors públicos), SHA-256, descompactação em background.
- FR-012 [MUST] Gestão térmica/bateria: threads 1-2, hash 16-64MB adaptativos, profundidade dinâmica (obvio ~10-12 / complexo ~16-20).
- FR-013 [MUST] Motor de regras local completo: roque (incl. 960), en passant, promoção, afogamento, 50 lances, repetição tripla.
- FR-014 [SHOULD] SRS SM-2 (1/3/7/14 dias) para repertório de aberturas.
- FR-015 [SHOULD] Explorador de aberturas ilimitado (Polyglot/ECO) com taxas de vitória.
- FR-016 [SHOULD] Retry Mistakes: puzzles gerados das gafes das partidas salvas.
- FR-017 [SHOULD] Radar de fraquezas por fase do jogo/cor/tática.
- FR-018 [SHOULD] Importador PGN (colar) + API pública Chess.com/Lichess por username.
- FR-019 [SHOULD] Pass & Play com tabuleiro espelhado e relógio duplo.
- FR-020 [SHOULD] P2P local (Bluetooth RFCOMM/Wi-Fi Direct) com troca de lances <15ms e permissões Android 31+ (BLUETOOTH_CONNECT/ACCESS_FINE_LOCATION).
- FR-021 [SHOULD] Card visual compartilhável (PNG/JPG) da partida.
- FR-022 [SHOULD] Xadrez 960 (posições 0-959), Modo Às Cegas e Treinador de Coordenadas (30s).

## Acceptance Criteria (SC)
- SC-001 APK debug compila e executa no emulador/девice arm64-v8a (e x86_64 p/ emulador).
- SC-002 FEN inicial avaliada com melhor lance em <50ms típico sem lock da thread de UI (teste unitário + smoke no device).
- SC-003 Concluir uma lição registra estrelas e desbloqueia o nó seguinte (persistência no Drift).
- SC-004 50+ puzzles consecutivos sem limite nem travamento.
- SC-005 Partida completa vs bot do lance 1 ao mate/efeita com regras especiais validadas por testes do motor de regras.
- SC-006 Análise de partida de 40 lances <10s no aparelho; classificação de cada lance com explicação PT-BR.
- SC-007 SSM-2 agenda revisões conforme intervalos e cobre variantes no treino (teste determinístico).
- SC-008 Pacote .zst baixado, validado por SHA-256 e descompactado integramente.
- SC-009 Testes de regras cobrem roque 960, en passant, promoção, afogamento, 50 lances e repetição tripla.
- SC-010 Build release APK <60MB com engine + assets embutidos.
