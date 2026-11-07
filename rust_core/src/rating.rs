use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RatingUpdate {
    pub old_rating: i32,
    pub new_rating: i32,
    pub change: i32,
    pub current_streak: u32,
    pub streak_bonus: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LadderState {
    pub score: u32,
    pub strikes: u32,
    pub max_strikes: u32,
    pub current_streak: u32,
    pub highest_streak: u32,
    pub is_game_over: bool,
    pub current_puzzle_idx: usize,
}

impl Default for LadderState {
    fn default() -> Self {
        Self::new(3)
    }
}

impl LadderState {
    pub fn new(max_strikes: u32) -> Self {
        Self {
            score: 0,
            strikes: 0,
            max_strikes,
            current_streak: 0,
            highest_streak: 0,
            is_game_over: false,
            current_puzzle_idx: 0,
        }
    }

    pub fn record_result(&mut self, is_correct: bool) {
        if self.is_game_over {
            return;
        }

        if is_correct {
            self.score += 1;
            self.current_streak += 1;
            if self.current_streak > self.highest_streak {
                self.highest_streak = self.current_streak;
            }
            self.current_puzzle_idx += 1;
        } else {
            self.strikes += 1;
            self.current_streak = 0;
            if self.strikes >= self.max_strikes {
                self.is_game_over = true;
            } else {
                self.current_puzzle_idx += 1;
            }
        }
    }
}

pub struct RatingCalculator;

impl RatingCalculator {
    /// Atualiza o rating do jogador após tentar resolver um quebra-cabeça
    /// Inclui multiplicador dopaminérgico de combo streak (3+ acertos = +20%, 5+ acertos = +40%)
    pub fn update_puzzle_rating(
        player_rating: i32,
        puzzle_rating: i32,
        is_success: bool,
        current_streak: u32,
    ) -> RatingUpdate {
        let expected = 1.0 / (1.0 + 10.0_f64.powf((puzzle_rating - player_rating) as f64 / 400.0));
        let actual = if is_success { 1.0 } else { 0.0 };

        let k = 32.0;
        let base_delta = (k * (actual - expected)).round() as i32;

        let streak_bonus = if is_success {
            if current_streak >= 5 {
                (base_delta as f64 * 0.40).round() as i32
            } else if current_streak >= 3 {
                (base_delta as f64 * 0.20).round() as i32
            } else {
                0
            }
        } else {
            0
        };

        let new_streak = if is_success { current_streak + 1 } else { 0 };
        let total_change = (base_delta + streak_bonus).clamp(-30, 45);
        let new_rating = (player_rating + total_change).max(100);

        RatingUpdate {
            old_rating: player_rating,
            new_rating,
            change: total_change,
            current_streak: new_streak,
            streak_bonus,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_puzzle_rating_win_increases_and_loss_decreases() {
        let win = RatingCalculator::update_puzzle_rating(1200, 1200, true, 0);
        assert!(win.change > 0);
        assert!(win.new_rating > 1200);

        let loss = RatingCalculator::update_puzzle_rating(1200, 1200, false, 0);
        assert!(loss.change < 0);
        assert!(loss.new_rating < 1200);
    }

    #[test]
    fn test_streak_bonus_multiplier_rewards_consistency() {
        let normal_win = RatingCalculator::update_puzzle_rating(1200, 1200, true, 0);
        let streak_win = RatingCalculator::update_puzzle_rating(1200, 1200, true, 5);

        assert!(streak_win.streak_bonus > 0);
        assert!(streak_win.change > normal_win.change);
    }

    #[test]
    fn test_ladder_state_game_over_after_3_strikes() {
        let mut ladder = LadderState::new(3);
        assert!(!ladder.is_game_over);

        ladder.record_result(true);
        ladder.record_result(true);
        assert_eq!(ladder.score, 2);
        assert_eq!(ladder.current_streak, 2);

        ladder.record_result(false);
        assert_eq!(ladder.strikes, 1);
        assert_eq!(ladder.current_streak, 0);

        ladder.record_result(false);
        ladder.record_result(false);
        assert_eq!(ladder.strikes, 3);
        assert!(ladder.is_game_over);
    }
}
