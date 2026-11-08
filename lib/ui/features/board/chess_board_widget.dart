import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:chess_d/services/chess_rust_ffi.dart';
import 'package:chess_d/ui/core/app_colors.dart';
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
        final boardMap = _parseBoardPieces(fen);
        final lightColor = (widget.theme != ChessTheme.tournamentGreen)
            ? widget.theme.lightSquareColor
            : ThemeController.instance.lightSquareColor;
        final darkColor = (widget.theme != ChessTheme.tournamentGreen)
            ? widget.theme.darkSquareColor
            : ThemeController.instance.darkSquareColor;
        final accent = ThemeController.instance.accentColor;

        return AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
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

                        final isSelected = selectedSquare == square;
                        final isLegalTarget = legalTargets.contains(square);
                        final isLastMove = lastFromSquare == square || lastToSquare == square;

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
                          squareColor = Color.alphaBlend(AppColors.squareLastMove, squareColor);
                        }
                        if (isSelected) {
                          squareColor = Color.alphaBlend(accent.withOpacity(0.55), squareColor);
                        }

                        // Sobreposição de Heatmap
                        if (squareHeatmap != null) {
                          final dom = squareHeatmap['dominance'] as int? ?? 0;
                          if (dom > 0) {
                            squareColor = Color.alphaBlend(Colors.blue.withOpacity((dom * 0.12).clamp(0.1, 0.45)), squareColor);
                          } else if (dom < 0) {
                            squareColor = Color.alphaBlend(Colors.red.withOpacity((dom.abs() * 0.12).clamp(0.1, 0.45)), squareColor);
                          }
                          if (squareHeatmap['is_undefended'] == true) {
                            squareColor = Color.alphaBlend(Colors.amber.withOpacity(0.35), squareColor);
                          }
                        }

                        final pieceChar = boardMap[square];
                        final isWhitePiece = pieceChar != null && pieceChar.toUpperCase() == pieceChar;
                        final pieceColor = isWhitePiece
                            ? ThemeController.instance.whitePieceColor
                            : ThemeController.instance.blackPieceColor;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onSquareTapped(square),
                            child: Container(
                              color: squareColor,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Peça de Xadrez (respeita modo blindfold e paleta customizada)
                                  if (pieceChar != null && !widget.isBlindfold)
                                    Text(
                                      _getPieceSymbol(pieceChar),
                                      style: TextStyle(
                                        fontSize: 34,
                                        height: 1.0,
                                        color: pieceColor,
                                        shadows: [
                                          Shadow(
                                            color: isWhitePiece ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.25),
                                            blurRadius: 4,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Indicador de Lance Legal (Ponto suave ou Anel de captura)
                                  if (isLegalTarget)
                                    Container(
                                      width: pieceChar != null ? 36 : 14,
                                      height: pieceChar != null ? 36 : 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: pieceChar != null ? Colors.transparent : accent.withOpacity(0.75),
                                        border: pieceChar != null
                                            ? Border.all(color: accent, width: 3.5)
                                            : null,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
