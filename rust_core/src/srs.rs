use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SrsCard {
    pub id: String,
    pub opening_name: String,
    pub fen: String,
    pub expected_move_uci: String,
    pub repetition: u32,
    pub interval_days: u32,
    pub ease_factor: f64,
    pub next_review_epoch: u64,
}

impl SrsCard {
    pub fn new(id: String, opening_name: String, fen: String, expected_move_uci: String) -> Self {
        Self {
            id,
            opening_name,
            fen,
            expected_move_uci,
            repetition: 0,
            interval_days: 1,
            ease_factor: 2.5,
            next_review_epoch: 0,
        }
    }

    /// Atualiza o cartão usando o algoritmo SuperMemo SM-2
    /// quality: nota de 0 a 5 dada pelo jogador ou derivada da precisão do lance
    /// current_epoch: timestamp atual em segundos
    pub fn review(&mut self, quality: u8, current_epoch: u64) {
        let q = quality.min(5) as f64;

        // Atualização do Fator de Facilidade (EF)
        // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        let delta_ef = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02);
        self.ease_factor = (self.ease_factor + delta_ef).clamp(1.3, 2.5);

        if quality >= 3 {
            // Sucesso na recordação
            if self.repetition == 0 {
                self.interval_days = 1;
            } else if self.repetition == 1 {
                self.interval_days = 6;
            } else {
                let next_interval = ((self.interval_days as f64) * self.ease_factor).round() as u32;
                self.interval_days = next_interval.max(self.interval_days + 1);
            }
            self.repetition += 1;
        } else {
            // Falha na recordação (reset de repetição e intervalo para 1 dia)
            self.repetition = 0;
            self.interval_days = 1;
        }

        // 86400 segundos = 1 dia
        self.next_review_epoch = current_epoch + (self.interval_days as u64) * 86400;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_srs_initial_state() {
        let card = SrsCard::new(
            "ita_1".to_string(),
            "Italian Game".to_string(),
            "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3".to_string(),
            "g8f6".to_string(),
        );

        assert_eq!(card.repetition, 0);
        assert_eq!(card.interval_days, 1);
        assert_eq!(card.ease_factor, 2.5);
    }

    #[test]
    fn test_srs_successful_progression() {
        let mut card = SrsCard::new(
            "sic_1".to_string(),
            "Sicilian Defense".to_string(),
            "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2".to_string(),
            "g1f3".to_string(),
        );

        let now = 1700000000;

        // 1ª revisão perfeita (q=5)
        card.review(5, now);
        assert_eq!(card.repetition, 1);
        assert_eq!(card.interval_days, 1);
        assert!(card.ease_factor >= 2.5);

        // 2ª revisão perfeita (q=5)
        card.review(5, now + 86400);
        assert_eq!(card.repetition, 2);
        assert_eq!(card.interval_days, 6);

        // 3ª revisão perfeita (q=5)
        card.review(5, now + 7 * 86400);
        assert_eq!(card.repetition, 3);
        assert!(card.interval_days >= 15);
    }

    #[test]
    fn test_srs_failure_resets_repetition() {
        let mut card = SrsCard::new(
            "qgd_1".to_string(),
            "Queen's Gambit".to_string(),
            "rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2".to_string(),
            "e7e6".to_string(),
        );

        let now = 1700000000;
        card.review(5, now);
        card.review(5, now + 86400);
        assert_eq!(card.repetition, 2);
        assert_eq!(card.interval_days, 6);

        // Jogador errou o lance (q=1)
        card.review(1, now + 7 * 86400);
        assert_eq!(card.repetition, 0);
        assert_eq!(card.interval_days, 1);
        assert!(card.ease_factor < 2.5);
        assert!(card.ease_factor >= 1.3);
    }
}
