use shakmaty::{
    fen::Fen,
    san::San,
    uci::UciMove,
    CastlingMode, Chess, Color, KnownOutcome, Move, Outcome, Position, Role, Square,
};
use std::str::FromStr;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MoveInfo {
    pub uci: String,
    pub san: String,
    pub from: String,
    pub to: String,
    pub promotion: Option<String>,
    pub is_capture: bool,
    pub is_check: bool,
    pub is_castling: bool,
    pub is_en_passant: bool,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PositionStatus {
    pub fen: String,
    pub is_check: bool,
    pub is_game_over: bool,
    pub outcome: Option<String>, // "1-0", "0-1", "1/2-1/2"
    pub termination_reason: Option<String>, // "checkmate", "stalemate", "insufficient_material", "50_moves", "repetition"
    pub turn: String,            // "white" or "black"
    pub halfmoves: u32,
    pub fullmoves: u32,
    pub legal_moves: Vec<MoveInfo>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct EvaluationResult {
    pub centipawns: i32,
    pub mate_in: Option<i32>,
    pub best_move_uci: Option<String>,
    pub best_move_san: Option<String>,
    pub depth_reached: u32,
    pub nodes_evaluated: u64,
}

pub struct ChessGame {
    pub pos: Chess,
    pub move_history: Vec<Move>,
    pub fen_history: Vec<String>,
}

impl Default for ChessGame {
    fn default() -> Self {
        Self::new()
    }
}

impl ChessGame {
    pub fn new() -> Self {
        let pos = Chess::default();
        let fen = format!("{}", Fen::from_position(&pos, shakmaty::EnPassantMode::Legal));
        Self {
            pos,
            move_history: Vec::new(),
            fen_history: vec![fen],
        }
    }

    pub fn from_fen(fen_str: &str) -> Result<Self, String> {
        let fen: Fen = fen_str.parse().map_err(|e| format!("FEN inválido: {:?}", e))?;
        let pos: Chess = fen
            .clone()
            .into_position(CastlingMode::Standard)
            .or_else(|_| fen.into_position(CastlingMode::Chess960))
            .map_err(|e| format!("Posição inválida do FEN: {:?}", e))?;
        let norm_fen = format!("{}", Fen::from_position(&pos, shakmaty::EnPassantMode::Legal));
        Ok(Self {
            pos,
            move_history: Vec::new(),
            fen_history: vec![norm_fen],
        })
    }

    pub fn current_fen(&self) -> String {
        format!("{}", Fen::from_position(&self.pos, shakmaty::EnPassantMode::Legal))
    }

    pub fn legal_moves(&self) -> Vec<MoveInfo> {
        let legals = self.pos.legal_moves();
        legals
            .iter()
            .map(|m| {
                let uci = format!("{}", m.to_uci(CastlingMode::Standard));
                let san = format!("{}", San::from_move(&self.pos, *m));
                let (from_sq, to_sq) = match m {
                    Move::Normal { from, to, .. } => (*from, *to),
                    Move::EnPassant { from, to } => (*from, *to),
                    Move::Castle { king, rook } => (*king, *rook),
                    Move::Put { to, .. } => (*to, *to),
                };
                let promotion = match m {
                    Move::Normal { promotion: Some(role), .. } => Some(format!("{:?}", role).to_lowercase()),
                    _ => None,
                };

                let mut clone_pos = self.pos.clone();
                clone_pos.play_unchecked(*m);
                let is_check = clone_pos.is_check();

                MoveInfo {
                    uci,
                    san,
                    from: format!("{}", from_sq),
                    to: format!("{}", to_sq),
                    promotion,
                    is_capture: m.is_capture(),
                    is_check,
                    is_castling: m.is_castle(),
                    is_en_passant: m.is_en_passant(),
                }
            })
            .collect()
    }

    pub fn play_uci(&mut self, uci_str: &str) -> Result<MoveInfo, String> {
        let uci = UciMove::from_str(uci_str).map_err(|e| format!("UCI inválido: {:?}", e))?;
        let m = uci
            .to_move(&self.pos)
            .map_err(|e| format!("Lance UCI ilegal para posição: {:?}", e))?;

        if !self.pos.is_legal(m) {
            return Err(format!("Lance ilegal: {}", uci_str));
        }

        let san = format!("{}", San::from_move(&self.pos, m));
        let (from_sq, to_sq) = match &m {
            Move::Normal { from, to, .. } => (*from, *to),
            Move::EnPassant { from, to } => (*from, *to),
            Move::Castle { king, rook } => (*king, *rook),
            Move::Put { to, .. } => (*to, *to),
        };
        let promotion = match &m {
            Move::Normal { promotion: Some(role), .. } => Some(format!("{:?}", role).to_lowercase()),
            _ => None,
        };

        self.pos.play_unchecked(m);
        self.move_history.push(m);
        let new_fen = self.current_fen();
        self.fen_history.push(new_fen);

        Ok(MoveInfo {
            uci: uci_str.to_string(),
            san,
            from: format!("{}", from_sq),
            to: format!("{}", to_sq),
            promotion,
            is_capture: m.is_capture(),
            is_check: self.pos.is_check(),
            is_castling: m.is_castle(),
            is_en_passant: m.is_en_passant(),
        })
    }

    pub fn status(&self) -> PositionStatus {
        let legal_moves = self.legal_moves();
        let is_check = self.pos.is_check();
        let outcome = self.pos.outcome();

        let (is_game_over, outcome_str, reason) = match outcome {
            Outcome::Known(KnownOutcome::Decisive { winner }) => {
                let out = match winner {
                    Color::White => "1-0",
                    Color::Black => "0-1",
                };
                (true, Some(out.to_string()), Some("checkmate".to_string()))
            }
            Outcome::Known(KnownOutcome::Draw) => {
                let r = if self.pos.is_stalemate() {
                    "stalemate"
                } else if self.pos.is_insufficient_material() {
                    "insufficient_material"
                } else {
                    "draw"
                };
                (true, Some("1/2-1/2".to_string()), Some(r.to_string()))
            }
            Outcome::Unknown => {
                if self.is_threefold_repetition() {
                    (true, Some("1/2-1/2".to_string()), Some("repetition".to_string()))
                } else if self.pos.halfmoves() >= 100 {
                    (true, Some("1/2-1/2".to_string()), Some("50_moves".to_string()))
                } else {
                    (false, None, None)
                }
            }
        };

        let turn = match self.pos.turn() {
            Color::White => "white",
            Color::Black => "black",
        };

        PositionStatus {
            fen: self.current_fen(),
            is_check,
            is_game_over,
            outcome: outcome_str,
            termination_reason: reason,
            turn: turn.to_string(),
            halfmoves: self.pos.halfmoves(),
            fullmoves: self.pos.fullmoves().get(),
            legal_moves,
        }
    }

    pub fn is_threefold_repetition(&self) -> bool {
        if self.fen_history.len() < 5 {
            return false;
        }
        let current_parts: Vec<&str> = self.fen_history.last().unwrap().split(' ').collect();
        if current_parts.len() < 4 {
            return false;
        }
        let board_state = format!("{} {} {} {}", current_parts[0], current_parts[1], current_parts[2], current_parts[3]);

        let count = self
            .fen_history
            .iter()
            .filter(|f| {
                let parts: Vec<&str> = f.split(' ').collect();
                if parts.len() >= 4 {
                    let s = format!("{} {} {} {}", parts[0], parts[1], parts[2], parts[3]);
                    s == board_state
                } else {
                    false
                }
            })
            .count();

        count >= 3
    }

    pub fn evaluate_depth(&self, depth: u32) -> EvaluationResult {
        let mut nodes = 0u64;
        let is_white = self.pos.turn() == Color::White;
        let (score, best_move) = alpha_beta(&self.pos, depth, -30000, 30000, is_white, &mut nodes);

        let (uci, san) = if let Some(m) = best_move {
            let u = format!("{}", m.to_uci(CastlingMode::Standard));
            let s = format!("{}", San::from_move(&self.pos, m));
            (Some(u), Some(s))
        } else {
            (None, None)
        };

        let mate_in = if score > 20000 {
            Some((30000 - score + 1) / 2)
        } else if score < -20000 {
            Some((-30000 - score) / 2)
        } else {
            None
        };

        EvaluationResult {
            centipawns: score,
            mate_in,
            best_move_uci: uci,
            best_move_san: san,
            depth_reached: depth,
            nodes_evaluated: nodes,
        }
    }
}

fn piece_value(role: Role) -> i32 {
    match role {
        Role::Pawn => 100,
        Role::Knight => 320,
        Role::Bishop => 330,
        Role::Rook => 500,
        Role::Queen => 900,
        Role::King => 20000,
    }
}

fn square_bonus(role: Role, color: Color, sq: Square) -> i32 {
    let rank = if color == Color::White { sq.rank() as i32 } else { 7 - sq.rank() as i32 };
    let file = sq.file() as i32;
    let center_dist = (file - 3).abs().min((file - 4).abs()) + (rank - 3).abs().min((rank - 4).abs());

    match role {
        Role::Pawn => rank * 10 - center_dist * 3,
        Role::Knight => 15 - center_dist * 5,
        Role::Bishop => 10 - center_dist * 3,
        Role::Rook => if rank == 6 { 20 } else { 0 },
        Role::Queen => 5 - center_dist * 2,
        Role::King => if rank <= 1 { 20 } else { -15 * rank },
    }
}

fn evaluate_static(pos: &Chess) -> i32 {
    let board = pos.board();
    let mut score = 0;

    for sq in Square::ALL {
        if let Some(piece) = board.piece_at(sq) {
            let val = piece_value(piece.role) + square_bonus(piece.role, piece.color, sq);
            if piece.color == Color::White {
                score += val;
            } else {
                score -= val;
            }
        }
    }

    score
}

pub fn alpha_beta(
    pos: &Chess,
    depth: u32,
    mut alpha: i32,
    mut beta: i32,
    maximizing: bool,
    nodes: &mut u64,
) -> (i32, Option<Move>) {
    *nodes += 1;

    let legals = pos.legal_moves();
    if legals.is_empty() {
        if pos.is_check() {
            return if maximizing { (-29000 - depth as i32, None) } else { (29000 + depth as i32, None) };
        }
        return (0, None);
    }

    if depth == 0 {
        return (evaluate_static(pos), None);
    }

    let mut best_move = None;

    if maximizing {
        let mut max_eval = -30000;
        for m in legals {
            let mut next_pos = pos.clone();
            next_pos.play_unchecked(m);
            let (eval, _) = alpha_beta(&next_pos, depth - 1, alpha, beta, false, nodes);
            if eval > max_eval {
                max_eval = eval;
                best_move = Some(m);
            }
            alpha = alpha.max(eval);
            if beta <= alpha {
                break;
            }
        }
        (max_eval, best_move)
    } else {
        let mut min_eval = 30000;
        for m in legals {
            let mut next_pos = pos.clone();
            next_pos.play_unchecked(m);
            let (eval, _) = alpha_beta(&next_pos, depth - 1, alpha, beta, true, nodes);
            if eval < min_eval {
                min_eval = eval;
                best_move = Some(m);
            }
            beta = beta.min(eval);
            if beta <= alpha {
                break;
            }
        }
        (min_eval, best_move)
    }
}
