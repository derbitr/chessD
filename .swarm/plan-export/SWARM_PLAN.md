<!--
AUTO-GENERATED EXPORT/CHECKPOINT SNAPSHOT — DO NOT EDIT
This file is NOT the live plan. It is a derived export artifact.
- The plan ledger is authoritative: SQLite after cutover, JSONL during file-shadow mode.
- .swarm/plan.json and .swarm/plan.md are derived projections.
Regenerated on: save_plan and phase_complete.
-->
# Aplicativo Mobile de Xadrez Soberano (Android)
Swarm: default
Phase: 1 [PENDING] | Updated: 2026-10-17T01:41:55.575Z

---
## Execution Profile
- Parallelization: enabled
- Max Concurrent Tasks: 10
- Council Parallel: yes
- Locked: no
- Auto Proceed: no
- Commit After Each Completed Task: no
- Planning Profile: balanced

---
## Phase 1: Fundação Flutter, Toolchain Nativa & Stockfish NNUE via FFI [PENDING]
- [ ] 1.1: Cobertura FR-001: scaffolding Flutter Android-only (package com.soberano.chess): minSdk 24, targetSdk 35, compileSdk 35, Kotlin, .gitignore, lint; app mínimo compilável. PINs de toolchain no README: NDK r27, CMake >=3.22. [MEDIUM] (files_touched: [".gitignore","analysis_options.yaml","android/app/build.gradle.kts","android/app/src/main/AndroidManifest.xml","lib/main.dart","pubspec.yaml"])
- [ ] 1.2: Cobertura FR-001: baseline de arquitetura — go_router (shell + rotas), Riverpod (state mgmt/DI), logging e error handling centralizados; responsividade mobile-first. [MEDIUM] (depends: 1.1) (files_touched: ["lib/data/services/logger_service.dart","lib/ui/core/app_shell.dart","lib/ui/core/router.dart","pubspec.yaml"])
- [ ] 1.3: Cobertura FR-002 (pipeline nativo): externalNativeBuild CMake no Gradle (NDK r27, CMake 3.22+), abiFilters [arm64-v8a, x86_64], lib native_smoke (função C trivial) validando o build nativo ponta a ponta via FFI smoke test. [MEDIUM] (depends: 1.1) (files_touched: ["android/app/build.gradle.kts","android/app/src/main/cpp/CMakeLists.txt","android/app/src/main/cpp/native_smoke.cpp","lib/data/services/native_lib_loader.dart"])
- [ ] 1.4: Cobertura FR-002: integrar Stockfish NNUE C++ on-device + driver UCI C-ABI (uci/isready/position/go/stop/bestmove), flags -O3 -flto -march=armv8-a+simd (arm64-v8a); pesos NNUE em assets/engine/ com SHA-256 no manifest; ownership de memória FFI documentado. [LARGE] (depends: 1.3) (files_touched: ["android/app/src/main/cpp/stockfish","android/app/src/main/cpp/stockfish_driver.cpp","assets/engine/manifest.json"])
- [ ] 1.5: Cobertura FR-002: bindings Dart FFI + StockfishService assíncrono em dart:isolate (canal UCI, parser FEN/lances com pattern matching Dart 3) — UI nunca bloqueia. [LARGE] (depends: 1.4) (files_touched: ["lib/data/services/bridge/stockfish_ffi_bindings.dart","lib/data/services/bridge/uci_message.dart","lib/data/services/stockfish_service.dart","lib/domain/models/engine_evaluation.dart"])
- [ ] 1.6: Cobertura FR-012: política térmica/bateria (profundidade dinâmica 10-12 óbvios / 16-20 complexos) com clock injetável + cache LRU de transposições; testes determinísticos sem sleeps reais. [MEDIUM] (depends: 1.5) (files_touched: ["lib/data/services/stockfish_thermal_policy.dart","lib/data/services/transposition_cache.dart","test/thermal_policy_test.dart"])
- [ ] 1.7: Cobertura FR-008: bots Elo 250-2800 humanizados (Skill Level, UCI_LimitStrength, imprecisões, delay 1-3s) com seed param + BOT_TEST_MODE; perfis Agressivo/Posicional/Mestre Clássico; TDD. [MEDIUM] (depends: 1.5) (files_touched: ["lib/domain/models/bot_profile.dart","lib/domain/use_cases/select_bot_move.dart","test/bot_profile_test.dart","test/select_bot_move_test.dart"])

---
## Phase 2: Design System & Pipeline de Conteúdo híbrido + Zstandard [PENDING]
- [ ] 2.1: Design System: tokens Obsidian #0B0F17, Slate #151C28, Ciano #00E5FF, Carmesim #FF1744, contraste >=12:1, variantes de tabuleiro (Verde Torneio/Nogal/Escuro). [MEDIUM] (depends: 1.2) (files_touched: ["lib/ui/core/app_colors.dart","lib/ui/core/app_typography.dart","lib/ui/core/chess_theme.dart"])
- [ ] 2.2: Cobertura FR-010 e FR-005: taxonomia REA clean-room (4 módulos: Fundamentos, Táticas, Finais, Estratégia) + síntese didática 100% original (pílulas 1-2min + 5-10 exercícios única-solução por nó), sem assets/textos proprietários. [MEDIUM] (files_touched: ["assets/lessons/lessons.json","lib/data/models/lesson.dart"])
- [ ] 2.3: Cobertura FR-003 e FR-006 (base de dados de puzzles): ETL de 20.000 puzzles — normalização (fen/moves UCI/rating/themes), dedupe, validação de solução única, saída intermediária revisável. Sem gerar assets no repo. [LARGE] (files_touched: ["tool/prepare_puzzles.py"])
- [ ] 2.4: Cobertura FR-003: empacotamento offline das 20k puzzles (codificação 16-bit + Zstandard .zst + SHA-256 no manifest, embarcado no APK); repository carrega/valida e consulta por tema/rating <5ms — funcional em modo avião. [LARGE] (depends: 1.3, 2.3) (files_touched: ["assets/puzzles/manifest.json","assets/puzzles/puzzles_20k.db","lib/data/repositories/puzzle_repository.dart","tool/package_puzzles.py"])
- [ ] 2.5: Cobertura FR-009 (persistência): SQLite/Drift — schema de partidas/histórico, progresso da trilha, métricas, repertório; migrations e índices, 100% local/offline. [MEDIUM] (depends: 1.1) (files_touched: ["lib/data/models/drift_tables.dart","lib/data/repositories/app_database.dart","pubspec.yaml"])

---
## Phase 3: Tabuleiro 120 FPS, Modos Especiais & P2P [PENDING]
- [ ] 3.1: ChessBoardWidget: 8x8 fluido, drag/tap, legal moves, premove, animações <120ms com reduced-motion; widget test. [LARGE] (depends: 2.1) (files_touched: ["lib/ui/features/board/board_theme.dart","lib/ui/features/board/chess_board_widget.dart","test/chess_board_test.dart"])
- [ ] 3.2: Cobertura FR-013: motor de regras local completo (roque normal, en passant, promoção, afogamento, 50 lances, repetição tripla) com TDD rigoroso. [LARGE] (depends: 1.1) (files_touched: ["lib/domain/chess_engine/move_generator.dart","lib/domain/chess_engine/position.dart","test/rules_engine_test.dart"])
- [ ] 3.3: Cobertura FR-008: tela de partida vs bots — seletor bot/avatar/Elo, relógio (bullet/blitz/rapid/livre), sons e háptica. [MEDIUM] (depends: 1.7, 3.1, 3.2) (files_touched: ["lib/ui/features/game/bot_match_screen.dart"])
- [ ] 3.4: Cobertura FR-022: Xadrez 960 (gerador posições 0-959 + regras de roque 960), Modo Às Cegas, Treinador de Coordenadas (30s, zona do polegar). [MEDIUM] (depends: 3.2) (files_touched: ["lib/domain/chess_engine/chess960.dart","lib/ui/features/game/blindfold_screen.dart","lib/ui/features/training/coordinate_trainer_screen.dart"])
- [ ] 3.5: Cobertura FR-019: Pass & Play com tabuleiro espelhado e relógio tátil duplo. [SMALL] (depends: 3.3) (files_touched: ["lib/ui/features/game/pass_and_play_screen.dart"])
- [ ] 3.6: Cobertura FR-020: P2P local Bluetooth RFCOMM/Wi-Fi Direct com troca de lances <15ms; permissões Android 31+ (BLUETOOTH_CONNECT, BLUETOOTH_SCAN, ACCESS_FINE_LOCATION runtime) declaradas e tratadas. [LARGE] (depends: 3.2) (files_touched: ["android/app/src/main/AndroidManifest.xml","lib/data/services/p2p_service.dart","lib/ui/features/game/p2p_match_screen.dart"])

---
## Phase 4: Trilha Duolingo & Modos de Treino [PENDING]
- [ ] 4.1: Cobertura FR-005: trilha vertical Duolingo — nós (bloqueado/disponível/estrelas 1-3), desbloqueio sequencial, curvas conectivas, progresso persistido no Drift. [LARGE] (depends: 2.2, 2.5) (files_touched: ["lib/data/repositories/progress_repository.dart","lib/domain/models/lesson_progress.dart","lib/ui/features/learning/learning_track_screen.dart"])
- [ ] 4.2: Cobertura FR-005: tela de Lição — teoria rápida + demonstração na posição + 5-10 exercícios com barra de progresso + chefão por módulo. [MEDIUM] (depends: 3.1, 4.1) (files_touched: ["lib/ui/features/learning/lesson_screen.dart"])
- [ ] 4.3: Cobertura FR-006 e FR-004: puzzles infinitos com rating tático adaptativo, sem limite diário/energia/lives — jogável indefinidamente offline. [MEDIUM] (depends: 2.4, 4.1) (files_touched: ["lib/domain/use_cases/update_tactical_rating.dart","lib/ui/features/training/infinite_puzzles_screen.dart"])
- [ ] 4.4: Cobertura FR-007: escada de problemas — sobrevivência (dificuldade crescente, 3 erros) ou cronometrada (3/5min) com combo streak e recordes locais. [MEDIUM] (depends: 4.3) (files_touched: ["lib/data/repositories/ladder_records_repository.dart","lib/ui/features/training/puzzle_ladder_screen.dart"])

---
## Phase 5: Análise Profunda, Coach IA & Share Card [PENDING]
- [ ] 5.1: Cobertura FR-009: gravação de partidas completas (PGN, resultado, precisão, metadados) no histórico local ilimitado e offline (FR-003). [MEDIUM] (depends: 2.5, 3.3) (files_touched: ["lib/data/repositories/game_repository.dart"])
- [ ] 5.2: Cobertura FR-009 e FR-004: análise pós-jogo assíncrona (depth 16-18) ilimitada e sem paywall — gráfico centipawn, Accuracy %, classificação de lances (!!/melhor/excelente/?!/erro/??), navegação por lance. [LARGE] (depends: 1.5, 5.1) (files_touched: ["lib/domain/use_cases/analyze_game.dart","lib/ui/features/analysis/eval_chart.dart","lib/ui/features/analysis/game_review_screen.dart"])
- [ ] 5.3: Coach IA: explicações pedagógicas em pt-BR para erros/gafes (causa tática do blunder). [MEDIUM] (depends: 5.2) (files_touched: ["lib/data/services/ai_coach_service.dart"])
- [ ] 5.4: Cobertura FR-021: card visual compartilhável (PNG/JPG) com resumo da partida, precisão e lances brilhantes. [SMALL] (depends: 5.2) (files_touched: ["lib/ui/features/analysis/share_card_widget.dart"])

---
## Phase 6: Módulos de Elite & Repetição Espaçada (SRS) [PENDING]
- [ ] 6.1: Cobertura FR-014: SRS SM-2 (intervalos 1/3/7/14 dias) para repertório de aberturas, com clock injetável e testes determinísticos. [MEDIUM] (depends: 2.5) (files_touched: ["lib/data/repositories/repertoire_repository.dart","lib/domain/use_cases/schedule_spaced_review.dart","test/sm2_scheduler_test.dart"])
- [ ] 6.2: Cobertura FR-015: explorador de aberturas ilimitado (Polyglot/ECO) com taxas de vitória, sem corte de profundidade. [MEDIUM] (depends: 6.1) (files_touched: ["assets/openings/openings.db","lib/data/repositories/opening_repository.dart","lib/ui/features/repertoire/opening_explorer_screen.dart"])
- [ ] 6.3: Cobertura FR-016: Retry Mistakes — extrai gafes/erros das partidas salvas e gera puzzles de correção. [MEDIUM] (depends: 5.2) (files_touched: ["lib/domain/use_cases/extract_mistake_puzzles.dart","lib/ui/features/analysis/retry_mistakes_screen.dart"])
- [ ] 6.4: Cobertura FR-017: radar de fraquezas por fase do jogo, cor e tipo de tática sofrida. [MEDIUM] (depends: 5.2) (files_touched: ["lib/ui/features/analysis/weakness_radar_screen.dart"])
- [ ] 6.5: Finais teóricos (Lucena, Philidor, oposição, mates elementares) contra defesa perfeita do Stockfish. [MEDIUM] (depends: 1.7, 3.2) (files_touched: ["assets/endgames/endgames.json","lib/ui/features/training/endgame_drills_screen.dart"])
- [ ] 6.6: Cobertura FR-018: importador de partidas — colar PGN livre + API pública Chess.com/Lichess por username. [SMALL] (depends: 5.1) (files_touched: ["lib/data/services/pgn_importer.dart","lib/ui/features/analysis/import_screen.dart"])

---
## Phase 7: Offline, Downloader 4M+ & Build do APK [PENDING]
- [ ] 7.1: Cobertura FR-011: downloader de pacotes 4M+ puzzles .zst sob demanda (mirrors públicos GitHub Releases/HuggingFace) com SHA-256 e decompactação em background. [LARGE] (depends: 2.4) (files_touched: ["lib/data/services/puzzle_downloader.dart","lib/ui/settings/packs_manager_screen.dart"])
- [ ] 7.2: Cobertura FR-012: otimização de bateria — threads 1-2 e hash 16-64MB adaptáveis ao dispositivo. [SMALL] (depends: 1.5) (files_touched: ["lib/data/services/stockfish_service.dart"])
- [ ] 7.3: Cobertura FR-003 (verificação final): suíte widget/integration tests (serial, 1 arquivo por rodada) e flutter build apk --release <60MB, 100% funcional em modo avião. [MEDIUM] (depends: 7.1, 7.2) (files_touched: ["android/app/build.gradle.kts","test"])
