use crate::engine::{alpha_beta, ChessGame, MoveInfo};
use rand::RngExt;
use shakmaty::san::San;
use shakmaty::{CastlingMode, Color, Move, Position};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub enum BotPersonality {
    Aggressive,
    Positional,
    Classical,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct BotProfile {
    pub name: String,
    pub elo: u32,
    pub personality: BotPersonality,
    pub avatar_id: String,
    pub description: String,
}

impl BotProfile {
    pub fn beginner() -> Self {
        Self {
            name: "Pawn Novice".to_string(),
            elo: 400,
            personality: BotPersonality::Classical,
            avatar_id: "novice_pawn".to_string(),
            description: "Um bot iniciante que frequentemente esquece defesas e comete gafes.".to_string(),
        }
    }

    pub fn intermediate_aggressive() -> Self {
        Self {
            name: "Valkyrie".to_string(),
            elo: 1200,
            personality: BotPersonality::Aggressive,
            avatar_id: "valkyrie_warrior".to_string(),
            description: "Uma adversária tática destemida que sempre busca atacar e abrir linhas contra o seu Rei.".to_string(),
        }
    }

    pub fn master_positional() -> Self {
        Self {
            name: "Grandmaster Boris".to_string(),
            elo: 2200,
            personality: BotPersonality::Positional,
            avatar_id: "gm_boris".to_string(),
            description: "Um mestre clássico que constrói posições sólidas e pune qualquer fraqueza estrutural.".to_string(),
        }
    }
}

pub struct BotPlayer {
    pub profile: BotProfile,
}

impl BotPlayer {
    pub fn new(profile: BotProfile) -> Self {
        Self { profile }
    }

    pub fn choose_move(&self, game: &ChessGame) -> Option<MoveInfo> {
        let legals = game.pos.legal_moves();
        if legals.is_empty() {
            return None;
        }

        let mut rng = rand::rng();
        let elo = self.profile.elo;

        // Probabilidade de gafe baseada no Elo
        let blunder_rate = if elo < 600 {
            0.50
        } else if elo < 1000 {
            0.30
        } else if elo < 1400 {
            0.15
        } else if elo < 1800 {
            0.05
        } else {
            0.0
        };

        // Se o bot cometer uma gafe deliberada compatível com o Elo:
        if rng.random_bool(blunder_rate) && legals.len() > 1 {
            let random_index = rng.random_range(0..legals.len());
            let m = &legals[random_index];
            return self.move_to_info(game, m);
        }

        // Profundidade calibrada por faixa de Elo
        let depth = if elo < 800 {
            1
        } else if elo < 1400 {
            2
        } else if elo < 2000 {
            3
        } else {
            4
        };

        let is_white = game.pos.turn() == Color::White;
        let mut scored_moves: Vec<(i32, Move)> = Vec::new();
        let mut nodes = 0;

        for m in &legals {
            let mut next_pos = game.pos.clone();
            next_pos.play_unchecked(*m);

            let (score, _) = alpha_beta(&next_pos, depth - 1, -30000, 30000, !is_white, &mut nodes);

            // Ajuste por personalidade
            let personality_bonus = match self.profile.personality {
                BotPersonality::Aggressive => {
                    let mut bonus = 0;
                    if m.is_capture() {
                        bonus += 25;
                    }
                    if next_pos.is_check() {
                        bonus += 35;
                    }
                    if is_white { bonus } else { -bonus }
                }
                BotPersonality::Positional => {
                    let mut bonus = 0;
                    if m.is_castle() {
                        bonus += 30;
                    }
                    if is_white { bonus } else { -bonus }
                }
                BotPersonality::Classical => 0,
            };

            let final_score = if is_white {
                score + personality_bonus
            } else {
                score - personality_bonus
            };

            scored_moves.push((final_score, *m));
        }

        if is_white {
            scored_moves.sort_by(|a, b| b.0.cmp(&a.0));
        } else {
            scored_moves.sort_by(|a, b| a.0.cmp(&b.0));
        }

        // Escolhe o melhor lance, ou um dos 2 melhores se o Elo for intermediário
        let chosen_move = if elo < 1500 && scored_moves.len() > 1 && rng.random_bool(0.25) {
            &scored_moves[1].1
        } else {
            &scored_moves[0].1
        };

        self.move_to_info(game, chosen_move)
    }

    fn move_to_info(&self, game: &ChessGame, m: &Move) -> Option<MoveInfo> {
        let uci = format!("{}", m.to_uci(CastlingMode::Standard));
        let san = format!("{}", San::from_move(&game.pos, *m));
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

        let mut clone_pos = game.pos.clone();
        clone_pos.play_unchecked(*m);
        let is_check = clone_pos.is_check();

        Some(MoveInfo {
            uci,
            san,
            from: format!("{}", from_sq),
            to: format!("{}", to_sq),
            promotion,
            is_capture: m.is_capture(),
            is_check,
            is_castling: m.is_castle(),
            is_en_passant: m.is_en_passant(),
        })
    }
}
