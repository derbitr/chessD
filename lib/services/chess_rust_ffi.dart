import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef ChessGameCreateC = Pointer<Void> Function();
typedef ChessGameCreateDart = Pointer<Void> Function();

typedef ChessGameCreateFromFenC = Pointer<Void> Function(Pointer<Utf8> fen);
typedef ChessGameCreateFromFenDart = Pointer<Void> Function(Pointer<Utf8> fen);

typedef ChessGameFreeC = Void Function(Pointer<Void> game);
typedef ChessGameFreeDart = void Function(Pointer<Void> game);

typedef ChessGameCurrentFenC = Pointer<Utf8> Function(Pointer<Void> game);
typedef ChessGameCurrentFenDart = Pointer<Utf8> Function(Pointer<Void> game);

typedef ChessGameStatusJsonC = Pointer<Utf8> Function(Pointer<Void> game);
typedef ChessGameStatusJsonDart = Pointer<Utf8> Function(Pointer<Void> game);

typedef ChessGamePlayUciC = Pointer<Utf8> Function(Pointer<Void> game, Pointer<Utf8> uci);
typedef ChessGamePlayUciDart = Pointer<Utf8> Function(Pointer<Void> game, Pointer<Utf8> uci);

typedef ChessGameEvaluateC = Pointer<Utf8> Function(Pointer<Void> game, Uint32 depth);
typedef ChessGameEvaluateDart = Pointer<Utf8> Function(Pointer<Void> game, int depth);

typedef ChessGameBotMoveC = Pointer<Utf8> Function(Pointer<Void> game, Uint32 botElo, Uint32 personality);
typedef ChessGameBotMoveDart = Pointer<Utf8> Function(Pointer<Void> game, int botElo, int personality);

typedef ChessGameHeatmapJsonC = Pointer<Utf8> Function(Pointer<Void> game);
typedef ChessGameHeatmapJsonDart = Pointer<Utf8> Function(Pointer<Void> game);

typedef Chess960RandomFenC = Pointer<Utf8> Function(Pointer<Uint16> outSeed);
typedef Chess960RandomFenDart = Pointer<Utf8> Function(Pointer<Uint16> outSeed);

typedef Chess960FenBySeedC = Pointer<Utf8> Function(Uint16 seed);
typedef Chess960FenBySeedDart = Pointer<Utf8> Function(int seed);

typedef ChessRatingUpdatePuzzleC = Pointer<Utf8> Function(Int32 playerRating, Int32 puzzleRating, Bool isSuccess, Uint32 currentStreak);
typedef ChessRatingUpdatePuzzleDart = Pointer<Utf8> Function(int playerRating, int puzzleRating, bool isSuccess, int currentStreak);

typedef ChessClassifyMoveC = Pointer<Utf8> Function(
  Bool isWhite,
  Pointer<Utf8> playedUci,
  Pointer<Utf8> bestUci,
  Int32 evalBefore,
  Int32 evalAfter,
  Bool isSacrifice,
  Uint32 timeSpentMs,
);
typedef ChessClassifyMoveDart = Pointer<Utf8> Function(
  bool isWhite,
  Pointer<Utf8> playedUci,
  Pointer<Utf8> bestUci,
  int evalBefore,
  int evalAfter,
  bool isSacrifice,
  int timeSpentMs,
);

typedef ChessSrsReviewC = Pointer<Utf8> Function(Pointer<Utf8> cardJson, Uint8 quality, Uint64 epoch);
typedef ChessSrsReviewDart = Pointer<Utf8> Function(Pointer<Utf8> cardJson, int quality, int epoch);

typedef ChessOpeningsCatalogJsonC = Pointer<Utf8> Function();
typedef ChessOpeningsCatalogJsonDart = Pointer<Utf8> Function();

typedef ChessOpeningsLookupEcoC = Pointer<Utf8> Function(Pointer<Utf8> eco);
typedef ChessOpeningsLookupEcoDart = Pointer<Utf8> Function(Pointer<Utf8> eco);

typedef ChessSwissGeneratePairingsC = Pointer<Utf8> Function(Pointer<Utf8> playersJson);
typedef ChessSwissGeneratePairingsDart = Pointer<Utf8> Function(Pointer<Utf8> playersJson);

typedef ChessSwissCalculateTiebreaksC = Pointer<Utf8> Function(Pointer<Utf8> playersJson);
typedef ChessSwissCalculateTiebreaksDart = Pointer<Utf8> Function(Pointer<Utf8> playersJson);

typedef ChessAntiCheatAuditC = Pointer<Utf8> Function(
  Pointer<Utf8> movesJson,
  Pointer<Utf8> top1Json,
  Pointer<Utf8> top2Json,
  Pointer<Utf8> cplsJson,
  Pointer<Utf8> timesJson,
);
typedef ChessAntiCheatAuditDart = Pointer<Utf8> Function(
  Pointer<Utf8> movesJson,
  Pointer<Utf8> top1Json,
  Pointer<Utf8> top2Json,
  Pointer<Utf8> cplsJson,
  Pointer<Utf8> timesJson,
);

typedef ChessNetworkClockSyncC = Pointer<Utf8> Function(Int64 t0, Int64 t1, Int64 t2, Int64 t3);
typedef ChessNetworkClockSyncDart = Pointer<Utf8> Function(int t0, int t1, int t2, int t3);

typedef ChessNetworkValidateRemoteMoveC = Pointer<Utf8> Function(
  Pointer<Utf8> fen,
  Uint8 fromSq,
  Uint8 toSq,
  Pointer<Utf8> promo,
  Int64 latencyMs,
);
typedef ChessNetworkValidateRemoteMoveDart = Pointer<Utf8> Function(
  Pointer<Utf8> fen,
  int fromSq,
  int toSq,
  Pointer<Utf8> promo,
  int latencyMs,
);

typedef ChessStringFreeC = Void Function(Pointer<Utf8> s);
typedef ChessStringFreeDart = void Function(Pointer<Utf8> s);

class ChessRustFfi {
  static DynamicLibrary? _lib;

  static DynamicLibrary get lib {
    if (_lib != null) return _lib!;

    if (Platform.isWindows) {
      final localDevPath = r'C:\Users\Breno\.gemini\antigravity\scratch\chess-app\rust_core\target\release\rust_core.dll';
      if (File(localDevPath).existsSync()) {
        _lib = DynamicLibrary.open(localDevPath);
      } else {
        _lib = DynamicLibrary.open('rust_core.dll');
      }
    } else if (Platform.isAndroid || Platform.isLinux) {
      _lib = DynamicLibrary.open('librust_core.so');
    } else if (Platform.isMacOS || Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Plataforma não suportada: ${Platform.operatingSystem}');
    }

    return _lib!;
  }

  late final ChessGameCreateDart _createGame;
  late final ChessGameCreateFromFenDart _createGameFromFen;
  late final ChessGameFreeDart _freeGame;
  late final ChessGameCurrentFenDart _currentFen;
  late final ChessGameStatusJsonDart _statusJson;
  late final ChessGamePlayUciDart _playUci;
  late final ChessGameEvaluateDart _evaluate;
  late final ChessGameBotMoveDart _botMove;
  late final ChessGameHeatmapJsonDart _heatmapJson;
  late final Chess960RandomFenDart _random960;
  late final Chess960FenBySeedDart _fenBySeed960;
  late final ChessRatingUpdatePuzzleDart _ratingUpdate;
  late final ChessClassifyMoveDart _classifyMove;
  late final ChessSrsReviewDart _srsReview;
  late final ChessOpeningsCatalogJsonDart _openingsCatalog;
  late final ChessOpeningsLookupEcoDart _openingsLookupEco;
  late final ChessSwissGeneratePairingsDart _swissPairings;
  late final ChessSwissCalculateTiebreaksDart _swissCalculateTiebreaks;
  late final ChessAntiCheatAuditDart _antiCheatAudit;
  late final ChessNetworkClockSyncDart _networkClockSync;
  late final ChessNetworkValidateRemoteMoveDart _networkValidateRemoteMove;
  late final ChessStringFreeDart _freeString;

  ChessRustFfi() {
    final dylib = lib;

    _createGame = dylib.lookupFunction<ChessGameCreateC, ChessGameCreateDart>('chess_game_create');
    _createGameFromFen = dylib.lookupFunction<ChessGameCreateFromFenC, ChessGameCreateFromFenDart>('chess_game_create_from_fen');
    _freeGame = dylib.lookupFunction<ChessGameFreeC, ChessGameFreeDart>('chess_game_free');
    _currentFen = dylib.lookupFunction<ChessGameCurrentFenC, ChessGameCurrentFenDart>('chess_game_current_fen');
    _statusJson = dylib.lookupFunction<ChessGameStatusJsonC, ChessGameStatusJsonDart>('chess_game_status_json');
    _playUci = dylib.lookupFunction<ChessGamePlayUciC, ChessGamePlayUciDart>('chess_game_play_uci');
    _evaluate = dylib.lookupFunction<ChessGameEvaluateC, ChessGameEvaluateDart>('chess_game_evaluate');
    _botMove = dylib.lookupFunction<ChessGameBotMoveC, ChessGameBotMoveDart>('chess_game_bot_move');
    _heatmapJson = dylib.lookupFunction<ChessGameHeatmapJsonC, ChessGameHeatmapJsonDart>('chess_game_heatmap_json');
    _random960 = dylib.lookupFunction<Chess960RandomFenC, Chess960RandomFenDart>('chess_960_random_fen');
    _fenBySeed960 = dylib.lookupFunction<Chess960FenBySeedC, Chess960FenBySeedDart>('chess_960_fen_by_seed');
    _ratingUpdate = dylib.lookupFunction<ChessRatingUpdatePuzzleC, ChessRatingUpdatePuzzleDart>('chess_rating_update_puzzle');
    _classifyMove = dylib.lookupFunction<ChessClassifyMoveC, ChessClassifyMoveDart>('chess_classify_move');
    _srsReview = dylib.lookupFunction<ChessSrsReviewC, ChessSrsReviewDart>('chess_srs_review');
    _openingsCatalog = dylib.lookupFunction<ChessOpeningsCatalogJsonC, ChessOpeningsCatalogJsonDart>('chess_openings_catalog_json');
    _openingsLookupEco = dylib.lookupFunction<ChessOpeningsLookupEcoC, ChessOpeningsLookupEcoDart>('chess_openings_lookup_eco');
    _swissPairings = dylib.lookupFunction<ChessSwissGeneratePairingsC, ChessSwissGeneratePairingsDart>('chess_swiss_generate_pairings');
    _swissCalculateTiebreaks = dylib.lookupFunction<ChessSwissCalculateTiebreaksC, ChessSwissCalculateTiebreaksDart>('chess_swiss_calculate_tiebreaks');
    _antiCheatAudit = dylib.lookupFunction<ChessAntiCheatAuditC, ChessAntiCheatAuditDart>('chess_anti_cheat_audit');
    _networkClockSync = dylib.lookupFunction<ChessNetworkClockSyncC, ChessNetworkClockSyncDart>('chess_network_clock_sync');
    _networkValidateRemoteMove = dylib.lookupFunction<ChessNetworkValidateRemoteMoveC, ChessNetworkValidateRemoteMoveDart>('chess_network_validate_remote_move');
    _freeString = dylib.lookupFunction<ChessStringFreeC, ChessStringFreeDart>('chess_string_free');
  }

  Pointer<Void> newGame() => _createGame();

  Pointer<Void> newGameFromFen(String fen) {
    final nativeFen = fen.toNativeUtf8();
    try {
      final ptr = _createGameFromFen(nativeFen);
      if (ptr.address == 0) {
        throw ArgumentError('FEN inválido para inicializar tabuleiro: $fen');
      }
      return ptr;
    } finally {
      calloc.free(nativeFen);
    }
  }

  void freeGame(Pointer<Void> game) => _freeGame(game);

  String getCurrentFen(Pointer<Void> game) {
    final ptr = _currentFen(game);
    if (ptr.address == 0) return '';
    try {
      return ptr.toDartString();
    } finally {
      _freeString(ptr);
    }
  }

  Map<String, dynamic> getStatus(Pointer<Void> game) {
    final ptr = _statusJson(game);
    if (ptr.address == 0) return {};
    try {
      final jsonStr = ptr.toDartString();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  Map<String, dynamic> playUci(Pointer<Void> game, String uci) {
    final nativeUci = uci.toNativeUtf8();
    try {
      final ptr = _playUci(game, nativeUci);
      if (ptr.address == 0) return {'error': 'Falha na execução nativa'};
      try {
        final jsonStr = ptr.toDartString();
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(nativeUci);
    }
  }

  Map<String, dynamic> evaluate(Pointer<Void> game, {int depth = 3}) {
    final ptr = _evaluate(game, depth);
    if (ptr.address == 0) return {};
    try {
      final jsonStr = ptr.toDartString();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  Map<String, dynamic>? getBotMove(Pointer<Void> game, {int elo = 1200, int personality = 0}) {
    final ptr = _botMove(game, elo, personality);
    if (ptr.address == 0) return null;
    try {
      final jsonStr = ptr.toDartString();
      if (jsonStr == 'null' || jsonStr.isEmpty) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  List<dynamic> getTacticalHeatmap(Pointer<Void> game) {
    final ptr = _heatmapJson(game);
    if (ptr.address == 0) return [];
    try {
      final jsonStr = ptr.toDartString();
      return jsonDecode(jsonStr) as List<dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  (int, String) getRandomChess960() {
    final seedPtr = calloc<Uint16>();
    try {
      final fenPtr = _random960(seedPtr);
      try {
        final fen = fenPtr.toDartString();
        final seed = seedPtr.value;
        return (seed, fen);
      } finally {
        _freeString(fenPtr);
      }
    } finally {
      calloc.free(seedPtr);
    }
  }

  String getChess960BySeed(int seed) {
    final fenPtr = _fenBySeed960(seed);
    try {
      return fenPtr.toDartString();
    } finally {
      _freeString(fenPtr);
    }
  }

  Map<String, dynamic> updatePuzzleRating({
    required int playerRating,
    required int puzzleRating,
    required bool isSuccess,
    required int currentStreak,
  }) {
    final ptr = _ratingUpdate(playerRating, puzzleRating, isSuccess, currentStreak);
    if (ptr.address == 0) return {};
    try {
      final jsonStr = ptr.toDartString();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  Map<String, dynamic> classifyMove({
    required bool isWhite,
    required String playedUci,
    required String bestUci,
    required int evalBefore,
    required int evalAfter,
    bool isSacrifice = false,
    int timeSpentMs = 0,
  }) {
    final playedPtr = playedUci.toNativeUtf8();
    final bestPtr = bestUci.toNativeUtf8();
    try {
      final ptr = _classifyMove(
        isWhite,
        playedPtr,
        bestPtr,
        evalBefore,
        evalAfter,
        isSacrifice,
        timeSpentMs,
      );
      if (ptr.address == 0) return {};
      try {
        final jsonStr = ptr.toDartString();
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(playedPtr);
      calloc.free(bestPtr);
    }
  }

  Map<String, dynamic> reviewSrsCard(Map<String, dynamic> card, int quality, int epoch) {
    final jsonIn = jsonEncode(card).toNativeUtf8();
    try {
      final ptr = _srsReview(jsonIn, quality, epoch);
      if (ptr.address == 0) return {};
      try {
        return jsonDecode(ptr.toDartString()) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(jsonIn);
    }
  }

  List<dynamic> getOpeningsCatalog() {
    final ptr = _openingsCatalog();
    if (ptr.address == 0) return [];
    try {
      return jsonDecode(ptr.toDartString()) as List<dynamic>;
    } finally {
      _freeString(ptr);
    }
  }

  Map<String, dynamic>? lookupOpeningEco(String eco) {
    final ecoPtr = eco.toNativeUtf8();
    try {
      final ptr = _openingsLookupEco(ecoPtr);
      if (ptr.address == 0) return null;
      try {
        final str = ptr.toDartString();
        if (str == 'null') return null;
        return jsonDecode(str) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(ecoPtr);
    }
  }

  Map<String, dynamic> generateSwissPairings(List<Map<String, dynamic>> players) {
    final jsonIn = jsonEncode(players).toNativeUtf8();
    try {
      final ptr = _swissPairings(jsonIn);
      if (ptr.address == 0) return {};
      try {
        return jsonDecode(ptr.toDartString()) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(jsonIn);
    }
  }

  List<Map<String, dynamic>> calculateTiebreaks(List<Map<String, dynamic>> players) {
    final jsonIn = jsonEncode(players).toNativeUtf8();
    try {
      final ptr = _swissCalculateTiebreaks(jsonIn);
      if (ptr.address == 0) return players;
      try {
        final decoded = jsonDecode(ptr.toDartString());
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return players;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(jsonIn);
    }
  }

  Map<String, dynamic> auditAntiCheat({
    required List<String> movesPlayed,
    required List<String> engineTop1,
    required List<String> engineTop2,
    required List<int> centipawnLosses,
    required List<int> moveTimesMs,
  }) {
    final movesPtr = jsonEncode(movesPlayed).toNativeUtf8();
    final top1Ptr = jsonEncode(engineTop1).toNativeUtf8();
    final top2Ptr = jsonEncode(engineTop2).toNativeUtf8();
    final cplsPtr = jsonEncode(centipawnLosses).toNativeUtf8();
    final timesPtr = jsonEncode(moveTimesMs).toNativeUtf8();
    try {
      final ptr = _antiCheatAudit(movesPtr, top1Ptr, top2Ptr, cplsPtr, timesPtr);
      if (ptr.address == 0) return {};
      try {
        return jsonDecode(ptr.toDartString()) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } finally {
      calloc.free(movesPtr);
      calloc.free(top1Ptr);
      calloc.free(top2Ptr);
      calloc.free(cplsPtr);
      calloc.free(timesPtr);
    }
  }

  Map<String, dynamic> calculateClockSync(int t0, int t1, int t2, int t3) {
    try {
      final ptr = _networkClockSync(t0, t1, t2, t3);
      if (ptr.address == 0) {
        return _fallbackClockSync(t0, t1, t2, t3);
      }
      try {
        return jsonDecode(ptr.toDartString()) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } catch (_) {
      return _fallbackClockSync(t0, t1, t2, t3);
    }
  }

  Map<String, dynamic> _fallbackClockSync(int t0, int t1, int t2, int t3) {
    final rtt = ((t3 - t0) - (t2 - t1)).clamp(0, 10000);
    final offset = (((t1 - t0) + (t2 - t3)) / 2).round();
    return {
      'rtt_ms': rtt,
      'clock_offset_ms': offset,
      'estimated_one_way_latency_ms': (rtt / 2).round(),
    };
  }

  Map<String, dynamic> validateRemoteMove({
    required String currentFen,
    required int fromSq,
    required int toSq,
    String? promotion,
    required int latencyMs,
  }) {
    final fenPtr = currentFen.toNativeUtf8();
    final promoPtr = promotion != null ? promotion.toNativeUtf8() : nullptr;
    try {
      final ptr = _networkValidateRemoteMove(fenPtr, fromSq, toSq, promoPtr, latencyMs);
      if (ptr.address == 0) {
        return {'is_legal': false, 'error_message': 'Falha FFI na validação'};
      }
      try {
        return jsonDecode(ptr.toDartString()) as Map<String, dynamic>;
      } finally {
        _freeString(ptr);
      }
    } catch (_) {
      return {'is_legal': false, 'error_message': 'Erro de execução FFI'};
    } finally {
      calloc.free(fenPtr);
      if (promoPtr != nullptr) calloc.free(promoPtr);
    }
  }
}
