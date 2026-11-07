use rand::RngExt;

pub struct Chess960;

impl Chess960 {
    /// Gera a primeira fileira para uma chave Fischer Random de 0 a 959
    pub fn generate_backrank(mut seed: u16) -> [char; 8] {
        seed %= 960;
        let mut rank = [' '; 8];

        // 1. Bispo de casas pretas (posições 1, 3, 5, 7)
        let b1 = (seed % 4) as usize * 2 + 1;
        rank[b1] = 'B';
        seed /= 4;

        // 2. Bispo de casas brancas (posições 0, 2, 4, 6)
        let b2 = (seed % 4) as usize * 2;
        rank[b2] = 'B';
        seed /= 4;

        // 3. Dama nas casas restantes
        let q_pos = (seed % 6) as usize;
        seed /= 6;

        let mut empty_idx = 0;
        for i in 0..8 {
            if rank[i] == ' ' {
                if empty_idx == q_pos {
                    rank[i] = 'Q';
                    break;
                }
                empty_idx += 1;
            }
        }

        // 4. Dois Cavalos nas 5 casas restantes
        let knight_table = [
            (0, 1), (0, 2), (0, 3), (0, 4),
            (1, 2), (1, 3), (1, 4),
            (2, 3), (2, 4),
            (3, 4),
        ];
        let (n1, n2) = knight_table[seed as usize];

        empty_idx = 0;
        for i in 0..8 {
            if rank[i] == ' ' {
                if empty_idx == n1 || empty_idx == n2 {
                    rank[i] = 'N';
                }
                empty_idx += 1;
            }
        }

        // 5. As 3 casas restantes obrigatoriamente recebem: Torre, Rei, Torre (Rei no meio)
        let mut remaining = Vec::new();
        for i in 0..8 {
            if rank[i] == ' ' {
                remaining.push(i);
            }
        }
        assert_eq!(remaining.len(), 3);
        rank[remaining[0]] = 'R';
        rank[remaining[1]] = 'K';
        rank[remaining[2]] = 'R';

        rank
    }

    /// Gera o FEN completo de uma partida Xadrez 960 a partir do número da posição (0..959)
    pub fn generate_fen(seed: u16) -> String {
        let backrank = Self::generate_backrank(seed);
        let white_back: String = backrank.iter().collect();
        let black_back = white_back.to_lowercase();

        format!("{}/pppppppp/8/8/8/8/PPPPPPPP/{} w KQkq - 0 1", black_back, white_back)
    }

    /// Sorteia aleatoriamente um número de 0 a 959 e devolve o FEN
    pub fn random_fen() -> (u16, String) {
        let mut rng = rand::rng();
        let seed = rng.random_range(0..960);
        (seed, Self::generate_fen(seed))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use shakmaty::{fen::Fen, CastlingMode, Chess};

    #[test]
    fn test_fischer_random_518_is_classical_chess() {
        // Posição 518 no índice padrão Fischer Random é o xadrez clássico (RNBQKBNR)
        let rank = Chess960::generate_backrank(518);
        let s: String = rank.iter().collect();
        assert_eq!(s, "RNBQKBNR");
    }

    #[test]
    fn test_all_960_positions_are_valid_and_have_opposite_bishops_and_king_between_rooks() {
        for seed in 0..960 {
            let rank = Chess960::generate_backrank(seed);

            // Verifica 2 bispos
            let bishops: Vec<usize> = rank.iter().enumerate().filter(|(_, &c)| c == 'B').map(|(i, _)| i).collect();
            assert_eq!(bishops.len(), 2);
            assert_ne!(bishops[0] % 2, bishops[1] % 2, "Bispos devem ser de cores opostas no seed {}", seed);

            // Verifica Rei entre Torres
            let rooks: Vec<usize> = rank.iter().enumerate().filter(|(_, &c)| c == 'R').map(|(i, _)| i).collect();
            let king: usize = rank.iter().position(|&c| c == 'K').unwrap();
            assert_eq!(rooks.len(), 2);
            assert!(rooks[0] < king && king < rooks[1], "Rei deve estar estritamente entre as duas torres no seed {}", seed);

            // Valida o FEN gerado
            let fen_str = Chess960::generate_fen(seed);
            let fen: Result<Fen, _> = fen_str.parse();
            assert!(fen.is_ok(), "FEN gerado para seed {} deve ser válido", seed);
            let pos: Result<Chess, _> = fen.unwrap().into_position(CastlingMode::Chess960);
            assert!(pos.is_ok(), "Posição 960 deve ser válida no shakmaty para seed {}", seed);
        }
    }
}
