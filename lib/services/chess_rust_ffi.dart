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
}
