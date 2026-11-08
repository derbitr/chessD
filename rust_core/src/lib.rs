pub mod anti_cheat;
pub mod bitboard_heatmap;
pub mod bot;
pub mod chess960;
pub mod engine;
pub mod ffi;
pub mod game_review;
pub mod openings;
pub mod rating;
pub mod srs;
pub mod tournament;
pub mod zstd_store;

#[cfg(test)]
mod tests {
    use super::bot::{BotPlayer, BotProfile};
    use super::engine::ChessGame;

    #[test]
    fn test_initial_position_and_legal_moves() {
        let game = ChessGame::new();
        let status = game.status();

        assert_eq!(status.turn, "white");
        assert!(!status.is_check);
        assert!(!status.is_game_over);
        assert_eq!(status.legal_moves.len(), 20);
    }

    #[test]
    fn test_fool_mate_checkmate_detection() {
        let mut game = ChessGame::new();

        game.play_uci("f2f3").expect("f2f3");
        game.play_uci("e7e5").expect("e7e5");
        game.play_uci("g2g4").expect("g2g4");
        let last_move = game.play_uci("d8h4").expect("d8h4");

        assert!(last_move.is_check);
        let status = game.status();
        assert!(status.is_check);
        assert!(status.is_game_over);
        assert_eq!(status.outcome, Some("0-1".to_string()));
        assert_eq!(status.termination_reason, Some("checkmate".to_string()));
        assert_eq!(status.legal_moves.len(), 0);
    }

    #[test]
    fn test_stalemate_detection() {
        let stalemate_game = ChessGame::from_fen("k7/2Q5/1K6/8/8/8/8/8 b - - 0 1").unwrap();
        let status = stalemate_game.status();

        assert!(!status.is_check);
        assert!(status.is_game_over);
        assert_eq!(status.outcome, Some("1/2-1/2".to_string()));
        assert_eq!(status.termination_reason, Some("stalemate".to_string()));
        assert_eq!(status.legal_moves.len(), 0);
    }

    #[test]
    fn test_en_passant_capture() {
        let mut game = ChessGame::new();
        game.play_uci("e2e4").unwrap();
        game.play_uci("g8f6").unwrap();
        game.play_uci("e4e5").unwrap();
        game.play_uci("d7d5").unwrap();

        let legals = game.legal_moves();
        let ep_move = legals.iter().find(|m| m.uci == "e5d6");
        assert!(ep_move.is_some(), "En passant e5d6 deve ser um lance legal");
        assert!(ep_move.unwrap().is_en_passant);

        let move_info = game.play_uci("e5d6").unwrap();
        assert!(move_info.is_capture);
        assert!(move_info.is_en_passant);
    }

    #[test]
    fn test_pawn_promotion() {
        let mut game = ChessGame::from_fen("7k/4P3/8/8/8/8/8/K7 w - - 0 1").unwrap();
        let legals = game.legal_moves();

        let promo_q = legals.iter().find(|m| m.uci == "e7e8q");
        let promo_r = legals.iter().find(|m| m.uci == "e7e8r");
        let promo_b = legals.iter().find(|m| m.uci == "e7e8b");
        let promo_n = legals.iter().find(|m| m.uci == "e7e8n");

        assert!(promo_q.is_some(), "Promoção para Rainha deve ser permitida");
        assert!(promo_r.is_some(), "Promoção para Torre deve ser permitida");
        assert!(promo_b.is_some(), "Promoção para Bispo deve ser permitida");
        assert!(promo_n.is_some(), "Promoção para Cavalo deve ser permitida");

        let res = game.play_uci("e7e8q").unwrap();
        assert_eq!(res.promotion, Some("queen".to_string()));
    }

    #[test]
    fn test_castling_rules_and_attacked_squares() {
        let game_ok = ChessGame::from_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1").unwrap();
        let legals_ok = game_ok.legal_moves();
        assert!(legals_ok.iter().any(|m| m.uci == "e1g1"), "Roque menor deve ser permitido");
        assert!(legals_ok.iter().any(|m| m.uci == "e1c1"), "Roque maior deve ser permitido");

        let game_blocked = ChessGame::from_fen("r3k2r/8/b7/8/8/8/8/R3K2R w KQkq - 0 1").unwrap();
        let legals_blocked = game_blocked.legal_moves();
        assert!(
            !legals_blocked.iter().any(|m| m.uci == "e1g1"),
            "Roque menor NÃO pode ser permitido quando f1 está atacada"
        );
    }

    #[test]
    fn test_threefold_repetition() {
        let mut game = ChessGame::new();
        assert!(!game.is_threefold_repetition());

        game.play_uci("g1f3").unwrap();
        game.play_uci("g8f6").unwrap();
        game.play_uci("f3g1").unwrap();
        game.play_uci("f6g8").unwrap();

        assert!(!game.status().is_game_over);

        game.play_uci("g1f3").unwrap();
        game.play_uci("g8f6").unwrap();
        game.play_uci("f3g1").unwrap();
        game.play_uci("f6g8").unwrap();

        let status = game.status();
        assert!(status.is_game_over);
        assert_eq!(status.termination_reason, Some("repetition".to_string()));
    }

    #[test]
    fn test_evaluation_finds_mate_in_one() {
        let game = ChessGame::from_fen("r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1n3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1").unwrap();
        let eval = game.evaluate_depth(2);

        assert_eq!(eval.best_move_uci, Some("h5f7".to_string()));
    }

    #[test]
    fn test_bot_does_not_crash_and_picks_legal_move() {
        let game = ChessGame::new();
        let bot = BotPlayer::new(BotProfile::intermediate_aggressive());

        let bot_move = bot.choose_move(&game);
        assert!(bot_move.is_some());
        let m = bot_move.unwrap();
        assert!(game.legal_moves().iter().any(|lm| lm.uci == m.uci));
    }
}
