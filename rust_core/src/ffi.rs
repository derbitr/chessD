use crate::bitboard_heatmap::TacticalHeatmap;
use crate::bot::{BotPersonality, BotPlayer, BotProfile};
use crate::chess960::Chess960;
use crate::engine::ChessGame;
use crate::game_review::{Caps2Evaluator, MoveAnalysis};
use crate::rating::RatingCalculator;
use crate::zstd_store::{PuzzleRecord, ZstdPuzzlePack};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

fn to_c_string(s: String) -> *mut c_char {
    CString::new(s).unwrap_or_default().into_raw()
}

#[no_mangle]
pub extern "C" fn chess_game_create() -> *mut ChessGame {
    let game = Box::new(ChessGame::new());
    Box::into_raw(game)
}

#[no_mangle]
pub extern "C" fn chess_game_create_from_fen(fen: *const c_char) -> *mut ChessGame {
    if fen.is_null() {
        return std::ptr::null_mut();
    }
    let c_str = unsafe { CStr::from_ptr(fen) };
    let fen_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match ChessGame::from_fen(fen_str) {
        Ok(game) => Box::into_raw(Box::new(game)),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn chess_game_free(game: *mut ChessGame) {
    if !game.is_null() {
        unsafe {
            drop(Box::from_raw(game));
        }
    }
}

#[no_mangle]
pub extern "C" fn chess_game_current_fen(game: *mut ChessGame) -> *mut c_char {
    if game.is_null() {
        return std::ptr::null_mut();
    }
    let game_ref = unsafe { &*game };
    to_c_string(game_ref.current_fen())
}

#[no_mangle]
pub extern "C" fn chess_game_status_json(game: *mut ChessGame) -> *mut c_char {
    if game.is_null() {
        return std::ptr::null_mut();
    }
    let game_ref = unsafe { &*game };
    let status = game_ref.status();
    let json_str = serde_json::to_string(&status).unwrap_or_default();
    to_c_string(json_str)
}

#[no_mangle]
pub extern "C" fn chess_game_play_uci(game: *mut ChessGame, uci: *const c_char) -> *mut c_char {
    if game.is_null() || uci.is_null() {
        return std::ptr::null_mut();
    }
    let game_mut = unsafe { &mut *game };
    let c_str = unsafe { CStr::from_ptr(uci) };
    let uci_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match game_mut.play_uci(uci_str) {
        Ok(move_info) => {
            let json = serde_json::to_string(&move_info).unwrap_or_default();
            to_c_string(json)
        }
        Err(err) => {
            let err_json = format!("{{\"error\":\"{}\"}}", err.replace('"', "\\\""));
            to_c_string(err_json)
        }
    }
}

#[no_mangle]
pub extern "C" fn chess_game_evaluate(game: *mut ChessGame, depth: u32) -> *mut c_char {
    if game.is_null() {
        return std::ptr::null_mut();
    }
    let game_ref = unsafe { &*game };
    let eval = game_ref.evaluate_depth(depth.clamp(1, 6));
    let json = serde_json::to_string(&eval).unwrap_or_default();
    to_c_string(json)
}

#[no_mangle]
pub extern "C" fn chess_game_bot_move(game: *mut ChessGame, bot_elo: u32, personality: u32) -> *mut c_char {
    if game.is_null() {
        return std::ptr::null_mut();
    }
    let game_ref = unsafe { &*game };

    let p = match personality {
        1 => BotPersonality::Aggressive,
        2 => BotPersonality::Positional,
        _ => BotPersonality::Classical,
    };

    let profile = BotProfile {
        name: format!("Bot Elo {}", bot_elo),
        elo: bot_elo,
        personality: p,
        avatar_id: "bot_auto".to_string(),
        description: "Bot calibrado".to_string(),
    };

    let bot = BotPlayer::new(profile);
    match bot.choose_move(game_ref) {
        Some(m) => {
            let json = serde_json::to_string(&m).unwrap_or_default();
            to_c_string(json)
        }
        None => to_c_string("null".to_string()),
    }
}

#[no_mangle]
pub extern "C" fn chess_game_heatmap_json(game: *mut ChessGame) -> *mut c_char {
    if game.is_null() {
        return std::ptr::null_mut();
    }
    let game_ref = unsafe { &*game };
    let heatmap = TacticalHeatmap::calculate(&game_ref.pos);
    let json = serde_json::to_string(&heatmap).unwrap_or_default();
    to_c_string(json)
}

#[no_mangle]
pub extern "C" fn chess_960_random_fen(out_seed: *mut u16) -> *mut c_char {
    let (seed, fen) = Chess960::random_fen();
    if !out_seed.is_null() {
        unsafe {
            *out_seed = seed;
        }
    }
    to_c_string(fen)
}

#[no_mangle]
pub extern "C" fn chess_960_fen_by_seed(seed: u16) -> *mut c_char {
    let fen = Chess960::generate_fen(seed);
    to_c_string(fen)
}

#[no_mangle]
pub extern "C" fn chess_rating_update_puzzle(
    player_rating: i32,
    puzzle_rating: i32,
    is_success: bool,
    current_streak: u32,
) -> *mut c_char {
    let update = RatingCalculator::update_puzzle_rating(player_rating, puzzle_rating, is_success, current_streak);
    let json = serde_json::to_string(&update).unwrap_or_default();
    to_c_string(json)
}

#[no_mangle]
pub extern "C" fn chess_classify_move(
    is_white: bool,
    played_uci: *const c_char,
    best_uci: *const c_char,
    eval_before: i32,
    eval_after: i32,
    is_sacrifice: bool,
    time_spent_ms: u32,
) -> *mut c_char {
    if played_uci.is_null() || best_uci.is_null() {
        return std::ptr::null_mut();
    }
    let played_str = unsafe { CStr::from_ptr(played_uci) }.to_str().unwrap_or_default();
    let best_str = unsafe { CStr::from_ptr(best_uci) }.to_str().unwrap_or_default();

    let (category, delta_w, accuracy) = Caps2Evaluator::classify_move(
        is_white,
        played_str,
        best_str,
        eval_before,
        eval_after,
        is_sacrifice,
    );

    let is_panic = time_spent_ms > 0 && time_spent_ms < 800 && (category == crate::game_review::MoveCategory::Blunder || category == crate::game_review::MoveCategory::Mistake);
    let explanation = Caps2Evaluator::explain_move_pt(&category, is_panic);

    let analysis = MoveAnalysis {
        move_number: 1,
        is_white,
        played_uci: played_str.to_string(),
        best_uci: best_str.to_string(),
        eval_before_cp: eval_before,
        eval_after_cp: eval_after,
        delta_win_pct: delta_w,
        move_accuracy: accuracy,
        category,
        pedagogical_explanation: explanation,
        time_spent_ms: Some(time_spent_ms),
        is_panic_move: is_panic,
    };

    let json = serde_json::to_string(&analysis).unwrap_or_default();
    to_c_string(json)
}

#[no_mangle]
pub extern "C" fn chess_zstd_compress_puzzles(json_str: *const c_char, out_len: *mut usize) -> *mut u8 {
    if json_str.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let c_str = unsafe { CStr::from_ptr(json_str) };
    let s = match c_str.to_str() {
        Ok(v) => v,
        Err(_) => return std::ptr::null_mut(),
    };

    let puzzles: Vec<PuzzleRecord> = match serde_json::from_str(s) {
        Ok(p) => p,
        Err(_) => return std::ptr::null_mut(),
    };

    match ZstdPuzzlePack::compress_puzzles(&puzzles) {
        Ok(mut bytes) => {
            bytes.shrink_to_fit();
            unsafe {
                *out_len = bytes.len();
            }
            let ptr = bytes.as_mut_ptr();
            std::mem::forget(bytes);
            ptr
        }
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn chess_zstd_decompress_puzzles(bytes_ptr: *const u8, len: usize) -> *mut c_char {
    if bytes_ptr.is_null() || len == 0 {
        return std::ptr::null_mut();
    }
    let slice = unsafe { std::slice::from_raw_parts(bytes_ptr, len) };
    match ZstdPuzzlePack::decompress_puzzles(slice) {
        Ok(puzzles) => {
            let json = serde_json::to_string(&puzzles).unwrap_or_default();
            to_c_string(json)
        }
        Err(e) => {
            let err = format!("{{\"error\":\"{}\"}}", e.replace('"', "\\\""));
            to_c_string(err)
        }
    }
}

#[no_mangle]
pub extern "C" fn chess_bytes_free(ptr: *mut u8, len: usize) {
    if !ptr.is_null() && len > 0 {
        unsafe {
            drop(Vec::from_raw_parts(ptr, len, len));
        }
    }
}

#[no_mangle]
pub extern "C" fn chess_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}
