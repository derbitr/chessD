import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/chess_theme.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessRustFfi ffi;
  final Pointer<Void> game;
  final bool isFlipped;
  final bool showHeatmap;
  final bool isBlindfold;
  final ChessTheme theme;
  final Function(String uci)? onMovePlayed;

  const ChessBoardWidget({
    super.key,
    required this.ffi,
    required this.game,
    this.isFlipped = false,
    this.showHeatmap = false,
    this.isBlindfold = false,
    this.theme = ChessTheme.tournamentGreen,
    this.onMovePlayed,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? selectedSquare;
  List<String> legalTargets = [];
  String? lastFromSquare;
  String? lastToSquare;
  Map<String, dynamic>? currentStatus;
  List<dynamic>? heatmapData;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  @override
  void didUpdateWidget(covariant ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshState();
  }

  void _refreshState() {
    setState(() {
      currentStatus = widget.ffi.getStatus(widget.game);
      if (widget.showHeatmap) {
        heatmapData = widget.ffi.getTacticalHeatmap(widget.game);
      } else {
        heatmapData = null;
      }
    });
  }

  void _onSquareTapped(String square) {
    if (currentStatus == null || (currentStatus!['is_game_over'] as bool? ?? false)) {
      return;
    }

    if (selectedSquare == null) {
      // Tentar selecionar peça
      final moves = (currentStatus!['legal_moves'] as List? ?? [])
          .where((m) => m['from'] == square)
          .toList();

      final targets = <String>{};
      for (final m in moves) {
        targets.add(m['to'].toString());
        if (m['is_castling'] == true) {
          final uci = m['uci']?.toString() ?? '';
          if (uci.length >= 4) {
            targets.add(uci.substring(2, 4));
          }
        }
      }

      if (targets.isNotEmpty) {
        setState(() {
          selectedSquare = square;
          legalTargets = targets.toList();
        });
      }
    } else {
      if (selectedSquare == square) {
        // Deselecionar
        setState(() {
          selectedSquare = null;
          legalTargets.clear();
        });
      } else if (legalTargets.contains(square)) {
        // Fazer lance
        final from = selectedSquare!;
        final to = square;

        // Trata promoção (por padrão Rainha se for peão alcançando a oitava/primeira fila)
        String uci = '$from$to';
        final isPromotion = (currentStatus!['legal_moves'] as List? ?? []).any(
          (m) => m['from'] == from && m['to'] == to && m['promotion'] != null,
        );
        if (isPromotion) {
          uci += 'q';
        }

        final res = widget.ffi.playUci(widget.game, uci);
        if (res['error'] == null) {
          setState(() {
            lastFromSquare = from;
            lastToSquare = to;
            selectedSquare = null;
            legalTargets.clear();
          });
          _refreshState();
          widget.onMovePlayed?.call(uci);
        }
      } else {
        // Tentar selecionar outra peça legal
        final moves = (currentStatus!['legal_moves'] as List? ?? [])
            .where((m) => m['from'] == square)
            .toList();

        final targets = <String>{};
        for (final m in moves) {
          targets.add(m['to'].toString());
          if (m['is_castling'] == true) {
            final uci = m['uci']?.toString() ?? '';
            if (uci.length >= 4) {
              targets.add(uci.substring(2, 4));
            }
          }
        }

        setState(() {
          if (targets.isNotEmpty) {
            selectedSquare = square;
            legalTargets = targets.toList();
          } else {
            selectedSquare = null;
            legalTargets.clear();
          }
        });
      }
    }
  }

  Map<String, String> _parseBoardPieces(String fen) {
    final pieces = <String, String>{};
    final parts = fen.split(' ');
    if (parts.isEmpty) return pieces;

    final rows = parts[0].split('/');
    for (int r = 0; r < 8 && r < rows.length; r++) {
      int file = 0;
      final rankNum = 8 - r;
      for (int c = 0; c < rows[r].length; c++) {
        final char = rows[r][c];
        final num = int.tryParse(char);
        if (num != null) {
          file += num;
        } else {
          if (file < 8) {
            final fileLetter = String.fromCharCode('a'.codeUnitAt(0) + file);
            final square = '$fileLetter$rankNum';
            pieces[square] = char;
            file += 1;
          }
        }
      }
    }
    return pieces;
  }

  String _getPieceSymbol(String char) {
    switch (char) {
      case 'P': return '♙';
      case 'N': return '♘';
      case 'B': return '♗';
      case 'R': return '♖';
      case 'Q': return '♕';
      case 'K': return '♔';
      case 'p': return '♟';
      case 'n': return '♞';
      case 'b': return '♝';
      case 'r': return '♜';
      case 'q': return '♛';
      case 'k': return '♚';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final fen = currentStatus?['fen'] as String? ?? '';
        final isCheck = currentStatus?['is_check'] as bool? ?? false;
        final turn = currentStatus?['turn'] as String? ?? 'white';
        final boardMap = _parseBoardPieces(fen);
        final lightColor = (widget.theme != ChessTheme.tournamentGreen)
            ? widget.theme.lightSquareColor
            : ThemeController.instance.lightSquareColor;
        final darkColor = (widget.theme != ChessTheme.tournamentGreen)
            ? widget.theme.darkSquareColor
            : ThemeController.instance.darkSquareColor;

        return AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final squareSize = constraints.maxWidth / 8;
                  final pieceFontSize = (squareSize * 0.72).clamp(22.0, 56.0);
                  final coordFontSize = (squareSize * 0.21).clamp(9.0, 13.0);

                  return Column(
                    children: List.generate(8, (rowIdx) {
                      final rank = widget.isFlipped ? rowIdx + 1 : 8 - rowIdx;

                      return Expanded(
                        child: Row(
                          children: List.generate(8, (colIdx) {
                            final fileNum = widget.isFlipped ? 7 - colIdx : colIdx;
                            final file = String.fromCharCode('a'.codeUnitAt(0) + fileNum);
                            final square = '$file$rank';

                            final isLight = (fileNum + rank) % 2 != 0;
                            final squareBaseColor = isLight ? lightColor : darkColor;
                            final coordColor = isLight ? darkColor : lightColor;

                            final isSelected = selectedSquare == square;
                            final isLegalTarget = legalTargets.contains(square);
                            final isLastMove = lastFromSquare == square || lastToSquare == square;

                            final pieceChar = boardMap[square];
                            final isKingInCheck = isCheck &&
                                pieceChar != null &&
                                ((turn == 'white' && pieceChar == 'K') ||
                                    (turn == 'black' && pieceChar == 'k'));

                            // Dados do Heatmap
                            dynamic squareHeatmap;
                            if (heatmapData != null) {
                              squareHeatmap = heatmapData!.firstWhere(
                                (h) => h['square'] == square,
                                orElse: () => null,
                              );
                            }

                            Color squareColor = squareBaseColor;
                            if (isLastMove) {
                              squareColor = Color.alphaBlend(
                                const Color(0xFFF7F769).withOpacity(0.42),
                                squareColor,
                              );
                            }
                            if (isSelected) {
                              squareColor = Color.alphaBlend(
                                const Color(0xFFBBCA2B).withOpacity(0.65),
                                squareColor,
                              );
                            }
                            if (isKingInCheck) {
                              squareColor = Color.alphaBlend(
                                Colors.red.withOpacity(0.65),
                                squareColor,
                              );
                            }

                            // Sobreposição de Heatmap
                            if (squareHeatmap != null) {
                              final dom = squareHeatmap['dominance'] as int? ?? 0;
                              if (dom > 0) {
                                squareColor = Color.alphaBlend(
                                  Colors.blue.withOpacity((dom * 0.12).clamp(0.1, 0.45)),
                                  squareColor,
                                );
                              } else if (dom < 0) {
                                squareColor = Color.alphaBlend(
                                  Colors.red.withOpacity((dom.abs() * 0.12).clamp(0.1, 0.45)),
                                  squareColor,
                                );
                              }
                              if (squareHeatmap['is_undefended'] == true) {
                                squareColor = Color.alphaBlend(
                                  Colors.amber.withOpacity(0.35),
                                  squareColor,
                                );
                              }
                            }

                            final isWhitePiece =
                                pieceChar != null && pieceChar.toUpperCase() == pieceChar;
                            final pieceColor = isWhitePiece
                                ? ThemeController.instance.whitePieceColor
                                : ThemeController.instance.blackPieceColor;

                            final isLeftEdge = colIdx == 0;
                            final isBottomEdge = rowIdx == 7;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _onSquareTapped(square),
                                child: Container(
                                  color: squareColor,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Coordenada de Fila (1-8) no canto superior esquerdo
                                      if (isLeftEdge)
                                        Positioned(
                                          top: 2,
                                          left: 3,
                                          child: Text(
                                            '$rank',
                                            style: TextStyle(
                                              fontSize: coordFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: coordColor.withOpacity(0.85),
                                              height: 1.0,
                                            ),
                                          ),
                                        ),

                                      // Coordenada de Coluna (a-h) no canto inferior direito
                                      if (isBottomEdge)
                                        Positioned(
                                          bottom: 2,
                                          right: 3,
                                          child: Text(
                                            file,
                                            style: TextStyle(
                                              fontSize: coordFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: coordColor.withOpacity(0.85),
                                              height: 1.0,
                                            ),
                                          ),
                                        ),

                                      // Peça de Xadrez com escala padronizada
                                      if (pieceChar != null && !widget.isBlindfold)
                                        Center(
                                          child: Text(
                                            _getPieceSymbol(pieceChar),
                                            style: TextStyle(
                                              fontSize: pieceFontSize,
                                              height: 1.0,
                                              color: pieceColor,
                                              shadows: [
                                                Shadow(
                                                  color: isWhitePiece
                                                      ? Colors.black.withOpacity(0.65)
                                                      : Colors.white.withOpacity(0.25),
                                                  blurRadius: 3,
                                                  offset: const Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      // Indicador de Lance Legal no estilo Chess.com
                                      if (isLegalTarget)
                                        Center(
                                          child: Container(
                                            width: pieceChar != null ? squareSize * 0.8 : squareSize * 0.28,
                                            height: pieceChar != null ? squareSize * 0.8 : squareSize * 0.28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: pieceChar != null
                                                  ? Colors.transparent
                                                  : Colors.black.withOpacity(0.22),
                                              border: pieceChar != null
                                                  ? Border.all(
                                                      color: Colors.black.withOpacity(0.25),
                                                      width: 3.5,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
