use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum MoveCategory {
    Brilliant,   // !!
    Great,       // !
    Best,        // ★
    Excellent,   // ✓
    Good,
    Inaccuracy,  // ?!
    Mistake,     // ?
    Blunder,     // ??
    Miss,
    Book,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoveAnalysis {
    pub move_number: u32,
    pub is_white: bool,
    pub played_uci: String,
    pub best_uci: String,
    pub eval_before_cp: i32,
    pub eval_after_cp: i32,
    pub delta_win_pct: f64,
    pub move_accuracy: f64,
    pub category: MoveCategory,
    pub pedagogical_explanation: String,
    pub time_spent_ms: Option<u32>,
    pub is_panic_move: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameReviewSummary {
    pub white_accuracy_pct: f64,
    pub black_accuracy_pct: f64,
    pub white_acl: f64, // Average Centipawn Loss
    pub black_acl: f64,
    pub white_brilliants: u32,
    pub black_brilliants: u32,
    pub white_blunders: u32,
    pub black_blunders: u32,
    pub white_mistakes: u32,
    pub black_mistakes: u32,
    pub white_inaccuracies: u32,
    pub black_inaccuracies: u32,
    pub moves: Vec<MoveAnalysis>,
    pub tilt_detected_player: Option<String>,
}

pub struct Caps2Evaluator;

impl Caps2Evaluator {
    /// Converte centipawns em probabilidade de vitória (0.0 a 1.0) usando a sigmoide canônica
    pub fn win_probability(centipawns: i32) -> f64 {
        let cp = centipawns.clamp(-3000, 3000) as f64;
        1.0 / (1.0 + (-0.00368208 * cp).exp())
    }

    /// Calcula a precisão do lance A_i a partir da perda de probabilidade de vitória (Delta W)
    pub fn move_accuracy(delta_win_pct: f64) -> f64 {
        let dw = (delta_win_pct * 100.0).max(0.0);
        let acc = 103.1668 * (-0.04354 * dw).exp() - 3.1669;
        acc.clamp(0.0, 100.0)
    }

    /// Classifica o lance didaticamente
    pub fn classify_move(
        is_white: bool,
        played_uci: &str,
        best_uci: &str,
        eval_before: i32,
        eval_after: i32,
        is_sacrifice: bool,
    ) -> (MoveCategory, f64, f64) {
        let w_before = Self::win_probability(if is_white { eval_before } else { -eval_before });
        let w_after = Self::win_probability(if is_white { eval_after } else { -eval_after });

        // Delta Win % do jogador da vez (quanto perdeu de probabilidade de vitória)
        let delta_w = (w_before - w_after).max(0.0);
        let acc = Self::move_accuracy(delta_w);

        let is_best = played_uci == best_uci;

        let category = if is_best {
            if is_sacrifice && (if is_white { eval_after } else { -eval_after }) > 150 {
                MoveCategory::Brilliant // Sacrifício tático vantajoso
            } else {
                MoveCategory::Best
            }
        } else if delta_w < 0.02 {
            MoveCategory::Excellent
        } else if delta_w < 0.05 {
            MoveCategory::Good
        } else if delta_w < 0.12 {
            MoveCategory::Inaccuracy
        } else if delta_w < 0.25 {
            MoveCategory::Mistake
        } else {
            MoveCategory::Blunder
        };

        (category, delta_w, acc)
    }

    /// Calcula o Índice de Tilt (TS em [0.0, 100.0]) baseado no perfil temporal e cascata de erros
    pub fn compute_tilt_score(
        fast_blunder_count: u32,
        has_blunder_cascade_2: bool,
        has_blunder_cascade_3_plus: bool,
        has_time_freeze: bool,
    ) -> f64 {
        let p_speed = (fast_blunder_count as f64) * 35.0;
        let b_cascade = if has_blunder_cascade_3_plus {
            50.0
        } else if has_blunder_cascade_2 {
            30.0
        } else {
            0.0
        };
        let t_freeze = if has_time_freeze { 25.0 } else { 0.0 };

        (p_speed + b_cascade + t_freeze).clamp(0.0, 100.0)
    }

    /// Gera explicação pedagógica em português para o lance
    pub fn explain_move_pt(category: &MoveCategory, is_panic: bool) -> String {
        let panic_str = if is_panic {
            " (Lance executado no desespero sob pressão de tempo!)"
        } else {
            ""
        };

        match category {
            MoveCategory::Brilliant => {
                format!("Brilhante (!!)! Um sacrifício tático espetacular que desmonta a defesa adversária e garante vitória forçada.{}", panic_str)
            }
            MoveCategory::Great => {
                format!("Ótimo lance (!)! Encontrou a linha mais precisa em uma posição complexa.{}", panic_str)
            }
            MoveCategory::Best => {
                "Melhor lance (★). Exatamente a linha recomendada pelo motor de análise.".to_string()
            }
            MoveCategory::Excellent => {
                "Excelente lance (✓). Mantém a sólida vantagem posicional sem riscos.".to_string()
            }
            MoveCategory::Good => {
                "Bom lance. O plano estratégico continua correto.".to_string()
            }
            MoveCategory::Inaccuracy => {
                format!("Imprecisão (?!). Cedeu ligeiramente o controle de espaço ou tempo ao oponente.{}", panic_str)
            }
            MoveCategory::Mistake => {
                format!("Erro (?). Uma oportunidade importante foi perdida, permitindo contra-jogo adversário.{}", panic_str)
            }
            MoveCategory::Blunder => {
                format!("Gafe (??)! Deixou peça indefesa ou permitiu um golpe tático decisivo contra o seu Rei.{}", panic_str)
            }
            MoveCategory::Miss => {
                "Oportunidade perdida (Miss). Você tinha uma vitória imediata ou golpe tático que passou despercebido.".to_string()
            }
            MoveCategory::Book => {
                "Lance teórico de livro de abertura.".to_string()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_win_probability_zero_cp_is_50_percent() {
        let prob = Caps2Evaluator::win_probability(0);
        assert!((prob - 0.50).abs() < 0.01);
    }

    #[test]
    fn test_caps2_accuracy_zero_loss_is_100_percent() {
        let acc = Caps2Evaluator::move_accuracy(0.0);
        assert!((acc - 100.0).abs() < 0.1);
    }

    #[test]
    fn test_caps2_accuracy_severe_loss_is_near_zero() {
        let acc = Caps2Evaluator::move_accuracy(0.50); // 50% de perda
        assert!(acc < 15.0);
    }

    #[test]
    fn test_move_classification_blunder_vs_best() {
        // Lance idêntico ao melhor lance
        let (cat_best, _, acc_best) = Caps2Evaluator::classify_move(true, "e2e4", "e2e4", 20, 20, false);
        assert_eq!(cat_best, MoveCategory::Best);
        assert!(acc_best > 95.0);

        // Lance com perda drástica de avaliação de +300 para -300 (perda de 600 centipawns)
        let (cat_blunder, _, acc_blunder) = Caps2Evaluator::classify_move(true, "h2h3", "e2e4", 300, -300, false);
        assert_eq!(cat_blunder, MoveCategory::Blunder);
        assert!(acc_blunder < 20.0);
    }

    #[test]
    fn test_compute_tilt_score_zen_vs_catastrophic() {
        // Sem erros nem pressa = Zen (0.0)
        let ts_zen = Caps2Evaluator::compute_tilt_score(0, false, false, false);
        assert_eq!(ts_zen, 0.0);

        // 2 gafes precipitadas + cascata de 3 erros = 2*35 + 50 = 120 -> clampado em 100
        let ts_catastrophic = Caps2Evaluator::compute_tilt_score(2, false, true, false);
        assert_eq!(ts_catastrophic, 100.0);
    }
}
