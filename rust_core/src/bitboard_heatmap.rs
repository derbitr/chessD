use shakmaty::{Chess, Color, Piece, Position, Square};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SquareTacticalInfo {
    pub square: String,
    pub white_attackers: u8,
    pub black_attackers: u8,
    pub piece: Option<String>,
    pub is_undefended: bool,
    pub dominance: i8, // > 0 controle branco, < 0 controle preto, 0 contestado
}

pub struct TacticalHeatmap;

impl TacticalHeatmap {
    /// Calcula o mapa de calor e controle tático de todas as 64 casas usando bitboards nativos
    pub fn calculate(pos: &Chess) -> Vec<SquareTacticalInfo> {
        let board = pos.board();
        let occupied = board.occupied();

        let mut result = Vec::with_capacity(64);

        for sq in Square::ALL {
            let white_attacks = board.attacks_to(sq, Color::White, occupied);
            let black_attacks = board.attacks_to(sq, Color::Black, occupied);

            let white_count = white_attacks.count() as u8;
            let black_count = black_attacks.count() as u8;

            let piece_opt = board.piece_at(sq);
            let piece_str = piece_opt.map(|p| match p {
                Piece { color: Color::White, role } => format!("W_{:?}", role).to_lowercase(),
                Piece { color: Color::Black, role } => format!("B_{:?}", role).to_lowercase(),
            });

            // Peça indefesa: tem peça na casa, mas seus defensores são 0
            let is_undefended = match piece_opt {
                Some(Piece { color: Color::White, .. }) => white_count == 0,
                Some(Piece { color: Color::Black, .. }) => black_count == 0,
                None => false,
            };

            let dominance = (white_count as i8) - (black_count as i8);

            result.push(SquareTacticalInfo {
                square: format!("{}", sq),
                white_attackers: white_count,
                black_attackers: black_count,
                piece: piece_str,
                is_undefended,
                dominance,
            });
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_initial_position_heatmap_center_dominance() {
        let pos = Chess::default();
        let heatmap = TacticalHeatmap::calculate(&pos);
        assert_eq!(heatmap.len(), 64);

        // e3 (square atacada diagonalmente por d2 e f2)
        let e3_info = heatmap.iter().find(|s| s.square == "e3").unwrap();
        assert!(e3_info.white_attackers > 0);
        assert_eq!(e3_info.black_attackers, 0);
        assert!(e3_info.dominance > 0);
    }
}
