use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TournamentPlayer {
    pub id: String,
    pub name: String,
    pub rating: i32,
    pub score: f32,
    pub buchholz: f32,
    pub sonneborn_berger: f32,
    pub opponents_played: Vec<String>,
    pub color_history: Vec<String>, // "W" or "B"
    pub had_bye: bool,
}

impl TournamentPlayer {
    pub fn new(id: String, name: String, rating: i32) -> Self {
        Self {
            id,
            name,
            rating,
            score: 0.0,
            buchholz: 0.0,
            sonneborn_berger: 0.0,
            opponents_played: Vec::new(),
            color_history: Vec::new(),
            had_bye: false,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TournamentPairing {
    pub white_player_id: String,
    pub black_player_id: String,
    pub result: Option<String>, // "1-0", "0-1", "1/2-1/2"
}

pub struct SwissTournament;

impl SwissTournament {
    /// Gera os emparceiramentos da próxima rodada segundo o Sistema Suíço simplificado FIDE
    pub fn generate_round_pairings(players: &mut [TournamentPlayer]) -> Vec<TournamentPairing> {
        if players.is_empty() {
            return Vec::new();
        }

        // Ordena jogadores por pontuação descrescente, desempate por rating
        let mut sorted_indices: Vec<usize> = (0..players.len()).collect();
        sorted_indices.sort_by(|&a, &b| {
            players[b].score.partial_cmp(&players[a].score)
                .unwrap_or(std::cmp::Ordering::Equal)
                .then_with(|| players[b].rating.cmp(&players[a].rating))
        });

        let mut pairings = Vec::new();
        let mut paired = vec![false; players.len()];

        // Se número ímpar de participantes, concede Bye (1.0 pt) ao último que ainda não teve
        if !sorted_indices.len().is_multiple_of(2) {
            for &idx in sorted_indices.iter().rev() {
                if !players[idx].had_bye {
                    players[idx].had_bye = true;
                    players[idx].score += 1.0;
                    paired[idx] = true;
                    break;
                }
            }
        }

        for i in 0..sorted_indices.len() {
            let p1_idx = sorted_indices[i];
            if paired[p1_idx] {
                continue;
            }

            // Busca o adversário elegível mais próximo na tabela de classificação
            let mut found_opponent = None;
            for j in (i + 1)..sorted_indices.len() {
                let p2_idx = sorted_indices[j];
                if paired[p2_idx] {
                    continue;
                }

                // Verifica se já jogaram
                let p2_id = &players[p2_idx].id;
                if !players[p1_idx].opponents_played.contains(p2_id) {
                    found_opponent = Some(p2_idx);
                    break;
                }
            }

            // Se todos já jogaram, pareia com o próximo disponível
            let opponent_idx = match found_opponent {
                Some(idx) => idx,
                None => {
                    match sorted_indices.iter().skip(i + 1).find(|&&idx| !paired[idx]) {
                        Some(&idx) => idx,
                        None => continue,
                    }
                }
            };

            paired[p1_idx] = true;
            paired[opponent_idx] = true;

            // Determinação de cores (Brancas vs Pretas) para equilibrar alternância
            let w_count_1 = players[p1_idx].color_history.iter().filter(|&c| c == "W").count();
            let b_count_1 = players[p1_idx].color_history.len() - w_count_1;
            let w_count_2 = players[opponent_idx].color_history.iter().filter(|&c| c == "W").count();
            let b_count_2 = players[opponent_idx].color_history.len() - w_count_2;

            let (white_id, black_id) = if (w_count_1 as i32 - b_count_1 as i32) > (w_count_2 as i32 - b_count_2 as i32) {
                (players[opponent_idx].id.clone(), players[p1_idx].id.clone())
            } else {
                (players[p1_idx].id.clone(), players[opponent_idx].id.clone())
            };

            pairings.push(TournamentPairing {
                white_player_id: white_id,
                black_player_id: black_id,
                result: None,
            });
        }

        pairings
    }

    /// Calcula os critérios de desempate (Buchholz e Sonneborn-Berger) para todos os jogadores
    pub fn calculate_tiebreaks(players: &mut [TournamentPlayer]) {
        let scores_map: std::collections::HashMap<String, f32> = players
            .iter()
            .map(|p| (p.id.clone(), p.score))
            .collect();

        for p in players.iter_mut() {
            let mut buchholz = 0.0;
            let mut sonneborn = 0.0;

            for opp_id in &p.opponents_played {
                if let Some(&opp_score) = scores_map.get(opp_id) {
                    buchholz += opp_score;
                    // Sonneborn-Berger simplificado
                    sonneborn += opp_score * 0.5;
                }
            }

            p.buchholz = buchholz;
            p.sonneborn_berger = sonneborn;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_swiss_pairings_even_players() {
        let mut players = vec![
            TournamentPlayer::new("p1".into(), "Magnus".into(), 2850),
            TournamentPlayer::new("p2".into(), "Hikaru".into(), 2800),
            TournamentPlayer::new("p3".into(), "Alireza".into(), 2780),
            TournamentPlayer::new("p4".into(), "Gukesh".into(), 2760),
        ];

        let pairings = SwissTournament::generate_round_pairings(&mut players);
        assert_eq!(pairings.len(), 2);
        assert_ne!(pairings[0].white_player_id, pairings[0].black_player_id);
    }

    #[test]
    fn test_swiss_pairings_odd_players_gives_bye() {
        let mut players = vec![
            TournamentPlayer::new("p1".into(), "Jogador 1".into(), 1600),
            TournamentPlayer::new("p2".into(), "Jogador 2".into(), 1500),
            TournamentPlayer::new("p3".into(), "Jogador 3".into(), 1400),
        ];

        let pairings = SwissTournament::generate_round_pairings(&mut players);
        // 1 partida pareada e 1 jogador recebeu Bye
        assert_eq!(pairings.len(), 1);
        let had_bye_count = players.iter().filter(|p| p.had_bye).count();
        assert_eq!(had_bye_count, 1);
    }

    #[test]
    fn test_swiss_tiebreaks_buchholz() {
        let mut players = vec![
            TournamentPlayer::new("p1".into(), "P1".into(), 2000),
            TournamentPlayer::new("p2".into(), "P2".into(), 1900),
            TournamentPlayer::new("p3".into(), "P3".into(), 1800),
        ];
        players[0].opponents_played = vec!["p2".into(), "p3".into()];
        players[1].score = 2.0;
        players[2].score = 1.0;

        SwissTournament::calculate_tiebreaks(&mut players);
        assert!((players[0].buchholz - 3.0).abs() < 1e-5);
    }
}
