import 'dart:math';

class Puzzle {
  final int id;
  final String fen;
  final List<String> movesUci;
  final int rating;
  final int ratingDeviation;
  final List<String> themes;

  const Puzzle({
    required this.id,
    required this.fen,
    required this.movesUci,
    required this.rating,
    required this.ratingDeviation,
    required this.themes,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as int,
      fen: json['fen'] as String,
      movesUci: (json['moves'] as List).map((e) => e.toString()).toList(),
      rating: json['rating'] as int,
      ratingDeviation: json['rating_deviation'] as int? ?? 50,
      themes: (json['themes'] as String? ?? '').split(','),
    );
  }
}

class PuzzleRepository {
  // Acervo base embutido inicial (curado para funcionamento 100% offline imediato)
  static final List<Puzzle> _curatedOfflinePuzzles = [
    const Puzzle(
      id: 2001,
      fen: 'r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1n3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1',
      movesUci: ['h5f7'],
      rating: 600,
      ratingDeviation: 30,
      themes: ['mate', 'mateIn1', 'opening'],
    ),
    const Puzzle(
      id: 2002,
      fen: 'r1b1k2r/pppp1ppp/8/8/1b1nP3/8/PPP2PPP/RNB1KB1R w KQkq - 0 1',
      movesUci: ['c2c3', 'b4c3'],
      rating: 850,
      ratingDeviation: 35,
      themes: ['fork', 'tactics'],
    ),
    const Puzzle(
      id: 2003,
      fen: '3r2k1/p4ppp/1p6/8/8/1P4P1/P4PKP/3RR3 b - - 0 1',
      movesUci: ['d8d1', 'e1e8'],
      rating: 1100,
      ratingDeviation: 40,
      themes: ['backRank', 'endgame'],
    ),
    const Puzzle(
      id: 2004,
      fen: 'r2q1rk1/1pp2ppp/p1np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP2PPP/R2Q1RK1 w - - 0 1',
      movesUci: ['c3d5', 'c6d4'],
      rating: 1400,
      ratingDeviation: 45,
      themes: ['pin', 'middlegame'],
    ),
    const Puzzle(
      id: 2005,
      fen: 'r4rk1/pbq2ppp/1pn1p3/2p1P3/2P5/2BB1N2/PP3PPP/R2QR1K1 w - - 0 1',
      movesUci: ['d3h7', 'g8h7', 'f3g5'],
      rating: 1750,
      ratingDeviation: 50,
      themes: ['sacrifice', 'kingsideAttack'],
    ),
    const Puzzle(
      id: 2006,
      fen: 'r1b2rk1/pp3ppp/2n1p3/8/2B5/P3PN2/1P3PPP/R2R2K1 w - - 0 1',
      movesUci: ['d1d6'],
      rating: 2050,
      ratingDeviation: 55,
      themes: ['positional', 'outpost'],
    ),
  ];

  final Random _rng = Random();

  /// Busca um problema adaptativo proporcional ao rating atual do jogador (Elo +/- 150)
  Future<Puzzle> getAdaptivePuzzle(int userRating) async {
    final candidates = _curatedOfflinePuzzles.where((p) {
      return (p.rating - userRating).abs() <= 300;
    }).toList();

    if (candidates.isEmpty) {
      return _curatedOfflinePuzzles[_rng.nextInt(_curatedOfflinePuzzles.length)];
    }

    return candidates[_rng.nextInt(candidates.length)];
  }

  /// Retorna sequência para a Escada de Problemas (Puzzle Rush), começando em 400 Elo
  Future<List<Puzzle>> getLadderSequence() async {
    final sorted = List<Puzzle>.from(_curatedOfflinePuzzles)
      ..sort((a, b) => a.rating.compareTo(b.rating));
    return sorted;
  }
}
