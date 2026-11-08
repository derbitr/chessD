use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ForensicVerdict {
    Clean,          // Padrão de jogo perfeitamente humano
    Inconclusive,   // Pequenas anomalias sem significância estatística
    Suspicious,     // Correlação atipicamente alta ou tempo excessivamente regular
    HighlyAnomalous,// Probabilidade extrema de assistência de motor (>99.5% confiança)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AntiCheatReport {
    pub total_moves: u32,
    pub top1_match_pct: f64,
    pub top2_match_pct: f64,
    pub average_centipawn_loss: f64,
    pub move_time_std_dev_ms: f64,
    pub cheat_probability_score: f64,
    pub verdict: ForensicVerdict,
    pub forensic_explanation: String,
}

pub struct AntiCheatAnalyzer;

impl AntiCheatAnalyzer {
    /// Executa a perícia forense sobre uma partida analisada
    pub fn analyze(
        moves_played: &[String],
        engine_top1_moves: &[String],
        engine_top2_moves: &[String],
        centipawn_losses: &[i32],
        move_times_ms: &[u32],
    ) -> AntiCheatReport {
        let n = moves_played.len();
        if n == 0 {
            return AntiCheatReport {
                total_moves: 0,
                top1_match_pct: 0.0,
                top2_match_pct: 0.0,
                average_centipawn_loss: 0.0,
                move_time_std_dev_ms: 0.0,
                cheat_probability_score: 0.0,
                verdict: ForensicVerdict::Clean,
                forensic_explanation: "Partida sem lances registrados para perícia.".to_string(),
            };
        }

        let mut top1_matches = 0;
        let mut top2_matches = 0;

        for i in 0..n {
            let played = &moves_played[i];
            if i < engine_top1_moves.len() && played == &engine_top1_moves[i] {
                top1_matches += 1;
                top2_matches += 1;
            } else if i < engine_top2_moves.len() && played == &engine_top2_moves[i] {
                top2_matches += 1;
            }
        }

        let top1_pct = (top1_matches as f64 / n as f64) * 100.0;
        let top2_pct = (top2_matches as f64 / n as f64) * 100.0;

        // ACL (Average Centipawn Loss)
        let total_cpl: i32 = centipawn_losses.iter().map(|&x| x.max(0)).sum();
        let acl = if !centipawn_losses.is_empty() {
            total_cpl as f64 / centipawn_losses.len() as f64
        } else {
            50.0
        };

        // Desvio padrão do tempo de decisão (em milissegundos)
        let std_dev = if move_times_ms.len() > 1 {
            let mean = move_times_ms.iter().sum::<u32>() as f64 / move_times_ms.len() as f64;
            let variance = move_times_ms
                .iter()
                .map(|&t| {
                    let diff = t as f64 - mean;
                    diff * diff
                })
                .sum::<f64>()
                / (move_times_ms.len() - 1) as f64;
            variance.sqrt()
        } else {
            1000.0
        };

        // Cálculo do Cheat Probability Score (CPS em [0.0, 100.0])
        // Fatores de suspeição:
        // 1. Alta concordância com a engine (top1 > 75%, top2 > 90%)
        // 2. ACL extremamente baixo (< 12)
        // 3. Desvio padrão de tempo não-humano (robótico: < 350ms em partidas longas)
        let mut score: f64 = 0.0;

        if top1_pct > 85.0 {
            score += (top1_pct - 85.0) * 3.5;
        } else if top1_pct > 72.0 {
            score += (top1_pct - 72.0) * 1.5;
        }

        if acl < 12.0 {
            score += (12.0 - acl) * 2.5;
        }

        if std_dev < 400.0 && n >= 15 {
            score += (400.0 - std_dev) * 0.08;
        }

        let cps = score.clamp(0.0, 100.0);

        let (verdict, explanation) = if cps < 30.0 {
            (
                ForensicVerdict::Clean,
                "Comportamento perfeitamente compatível com jogadores humanos. Variação natural de tempo e imprecisões normais.".to_string(),
            )
        } else if cps < 60.0 {
            (
                ForensicVerdict::Inconclusive,
                "Partida de alto nível técnico, mas dentro dos parâmetros estatísticos plausíveis de precisão humana.".to_string(),
            )
        } else if cps < 80.0 {
            (
                ForensicVerdict::Suspicious,
                "Atenção: Concordância atípica com as melhores escolhas da engine combinada com baixa perda de centipawns.".to_string(),
            )
        } else {
            (
                ForensicVerdict::HighlyAnomalous,
                "Alerta Forense Crítico: Correlação sobre-humana de lances e cadência artificial de tempo. Elevadíssima probabilidade de assistência externa.".to_string(),
            )
        };

        AntiCheatReport {
            total_moves: n as u32,
            top1_match_pct: top1_pct,
            top2_match_pct: top2_pct,
            average_centipawn_loss: acl,
            move_time_std_dev_ms: std_dev,
            cheat_probability_score: cps,
            verdict,
            forensic_explanation: explanation,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_anti_cheat_human_casual_game_is_clean() {
        let moves = vec!["e2e4".into(), "g1f3".into(), "f1c4".into(), "b1c3".into(), "d2d3".into()];
        let top1 = vec!["e2e4".into(), "c2c4".into(), "f1b5".into(), "d2d4".into(), "e1g1".into()];
        let top2 = vec!["d2d4".into(), "g1f3".into(), "f1c4".into(), "b1c3".into(), "c2c4".into()];
        let cpls = vec![0, 35, 40, 20, 60];
        let times = vec![1200, 3500, 800, 4200, 2100];

        let report = AntiCheatAnalyzer::analyze(&moves, &top1, &top2, &cpls, &times);
        assert_eq!(report.verdict, ForensicVerdict::Clean);
        assert!(report.cheat_probability_score < 30.0);
    }

    #[test]
    fn test_anti_cheat_engine_assisted_game_is_flagged() {
        // 20 lances idênticos ao Top-1 da engine com tempo robótico de 1000ms
        let moves: Vec<String> = (0..20).map(|i| format!("m_{}", i)).collect();
        let top1 = moves.clone();
        let top2 = moves.clone();
        let cpls = vec![2; 20];
        let times = vec![1000; 20];

        let report = AntiCheatAnalyzer::analyze(&moves, &top1, &top2, &cpls, &times);
        assert_eq!(report.verdict, ForensicVerdict::HighlyAnomalous);
        assert!(report.cheat_probability_score >= 80.0);
        assert!(report.top1_match_pct >= 99.0);
    }
}
