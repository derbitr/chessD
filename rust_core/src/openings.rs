use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct OpeningMoveOption {
    pub uci: String,
    pub san: String,
    pub white_win_pct: f32,
    pub draw_pct: f32,
    pub black_win_pct: f32,
    pub popularity_games: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct OpeningInfo {
    pub eco: String,
    pub name: String,
    pub moves_san: Vec<String>,
    pub initial_fen: String,
    pub candidate_moves: Vec<OpeningMoveOption>,
    pub strategic_summary: String,
}

pub struct OpeningBook;

impl OpeningBook {
    pub fn get_curated_openings() -> Vec<OpeningInfo> {
        vec![
            OpeningInfo {
                eco: "C50".to_string(),
                name: "Abertura Italiana (Giuoco Piano)".to_string(),
                moves_san: vec!["e4".into(), "e5".into(), "Nf3".into(), "Nc6".into(), "Bc4".into(), "Bc5".into()],
                initial_fen: "r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4".to_string(),
                candidate_moves: vec![
                    OpeningMoveOption { uci: "c2c3".into(), san: "c3".into(), white_win_pct: 38.0, draw_pct: 36.0, black_win_pct: 26.0, popularity_games: 125000 },
                    OpeningMoveOption { uci: "d2d3".into(), san: "d3".into(), white_win_pct: 36.0, draw_pct: 42.0, black_win_pct: 22.0, popularity_games: 98000 },
                    OpeningMoveOption { uci: "b2b4".into(), san: "b4".into(), white_win_pct: 39.0, draw_pct: 28.0, black_win_pct: 33.0, popularity_games: 45000 }, // Evans Gambit
                ],
                strategic_summary: "Visão harmônica com pressão direta na casa f7. O lance c3 prepara o controle total das casas centrais com d4.".to_string(),
            },
            OpeningInfo {
                eco: "C65".to_string(),
                name: "Abertura Ruy Lopez (Espanhola)".to_string(),
                moves_san: vec!["e4".into(), "e5".into(), "Nf3".into(), "Nc6".into(), "Bb5".into()],
                initial_fen: "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3".to_string(),
                candidate_moves: vec![
                    OpeningMoveOption { uci: "a7a6".into(), san: "a6".into(), white_win_pct: 37.0, draw_pct: 41.0, black_win_pct: 22.0, popularity_games: 340000 },
                    OpeningMoveOption { uci: "g8f6".into(), san: "Nf6".into(), white_win_pct: 34.0, draw_pct: 46.0, black_win_pct: 20.0, popularity_games: 180000 }, // Berlim
                ],
                strategic_summary: "A abertura mais clássica e profunda do xadrez. O Bispo crava indiretamente a peça que defende o peão central e5.".to_string(),
            },
            OpeningInfo {
                eco: "B90".to_string(),
                name: "Defesa Siciliana (Variante Najdorf)".to_string(),
                moves_san: vec!["e4".into(), "c5".into(), "Nf3".into(), "d6".into(), "d4".into(), "cxd4".into(), "Nxd4".into(), "Nf6".into(), "Nc3".into(), "a6".into()],
                initial_fen: "rnbqkb1r/1p2pppp/p2p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R w KQkq - 0 6".to_string(),
                candidate_moves: vec![
                    OpeningMoveOption { uci: "c1e3".into(), san: "Be3".into(), white_win_pct: 38.0, draw_pct: 32.0, black_win_pct: 30.0, popularity_games: 210000 }, // Ataque Inglês
                    OpeningMoveOption { uci: "f1e2".into(), san: "Be2".into(), white_win_pct: 35.0, draw_pct: 40.0, black_win_pct: 25.0, popularity_games: 140000 }, // Anatoly Karpov
                    OpeningMoveOption { uci: "c1g5".into(), san: "Bg5".into(), white_win_pct: 40.0, draw_pct: 28.0, black_win_pct: 32.0, popularity_games: 115000 }, // Bobby Fischer
                ],
                strategic_summary: "A arma predileta de Kasparov e Fischer. As Pretas lutam pela iniciativa assimétrica na ala da dama.".to_string(),
            },
            OpeningInfo {
                eco: "D35".to_string(),
                name: "Gambito da Dama Recusado".to_string(),
                moves_san: vec!["d4".into(), "d5".into(), "c4".into(), "e6".into(), "Nc3".into(), "Nf6".into()],
                initial_fen: "rnbqkb1r/ppp2ppp/4pn2/3p4/2PP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 2 4".to_string(),
                candidate_moves: vec![
                    OpeningMoveOption { uci: "c1g5".into(), san: "Bg5".into(), white_win_pct: 39.0, draw_pct: 41.0, black_win_pct: 20.0, popularity_games: 195000 },
                    OpeningMoveOption { uci: "c4d5".into(), san: "cxd5".into(), white_win_pct: 37.0, draw_pct: 44.0, black_win_pct: 19.0, popularity_games: 160000 },
                ],
                strategic_summary: "Estrutura hiper-sólida das Pretas, sustentando d5 contra a pressão do peão c4 das Brancas.".to_string(),
            },
            OpeningInfo {
                eco: "E60".to_string(),
                name: "Defesa Índia do Rei".to_string(),
                moves_san: vec!["d4".into(), "Nf6".into(), "c4".into(), "g6".into(), "Nc3".into(), "Bg7".into()],
                initial_fen: "rnbqk2r/ppppppbp/5np1/8/2PP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 2 4".to_string(),
                candidate_moves: vec![
                    OpeningMoveOption { uci: "e2e4".into(), san: "e4".into(), white_win_pct: 39.0, draw_pct: 33.0, black_win_pct: 28.0, popularity_games: 280000 },
                    OpeningMoveOption { uci: "g1f3".into(), san: "Nf3".into(), white_win_pct: 36.0, draw_pct: 38.0, black_win_pct: 26.0, popularity_games: 95000 },
                ],
                strategic_summary: "Estratégia hipermoderna: as Pretas cedem o centro inicialmente para lançar um ataque violento na ala do Rei com f5.".to_string(),
            },
        ]
    }

    pub fn find_by_eco(eco: &str) -> Option<OpeningInfo> {
        Self::get_curated_openings().into_iter().find(|o| o.eco == eco)
    }

    pub fn find_by_fen(fen_prefix: &str) -> Option<OpeningInfo> {
        Self::get_curated_openings().into_iter().find(|o| o.initial_fen.starts_with(fen_prefix))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_opening_book_lookup_italian() {
        let italian = OpeningBook::find_by_eco("C50");
        assert!(italian.is_some());
        let info = italian.unwrap();
        assert_eq!(info.name, "Abertura Italiana (Giuoco Piano)");
        assert_eq!(info.candidate_moves.len(), 3);
        assert_eq!(info.candidate_moves[0].san, "c3");
    }

    #[test]
    fn test_opening_book_candidates_have_valid_probabilities() {
        for opening in OpeningBook::get_curated_openings() {
            assert!(!opening.name.is_empty());
            assert!(!opening.eco.is_empty());
            for cand in opening.candidate_moves {
                let total = cand.white_win_pct + cand.draw_pct + cand.black_win_pct;
                assert!((total - 100.0).abs() < 1.0, "Total pct must be close to 100%");
            }
        }
    }
}
