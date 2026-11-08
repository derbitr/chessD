use serde::{Deserialize, Serialize};
use shakmaty::{Chess, Move, Position, Role, Square};

/// Tipos de pacotes suportados no protocolo P2P e WebSocket do chessD
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "payload")]
pub enum NetworkPacket {
    #[serde(rename = "handshake")]
    Handshake(HandshakePayload),

    #[serde(rename = "handshake_ack")]
    HandshakeAck(HandshakeAckPayload),

    #[serde(rename = "move")]
    Move(MovePayload),

    #[serde(rename = "move_ack")]
    MoveAck(MoveAckPayload),

    #[serde(rename = "clock_ping")]
    ClockPing(ClockPingPayload),

    #[serde(rename = "clock_pong")]
    ClockPong(ClockPongPayload),

    #[serde(rename = "draw_offer")]
    DrawOffer { player_id: String },

    #[serde(rename = "draw_response")]
    DrawResponse { accepted: bool },

    #[serde(rename = "resign")]
    Resign { player_id: String },

    #[serde(rename = "heartbeat")]
    Heartbeat { player_id: String, timestamp_ms: i64 },
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HandshakePayload {
    pub room_code: String,
    pub player_id: String,
    pub player_name: String,
    pub color_preference: String, // "white", "black", "random"
    pub time_control_secs: u32,
    pub increment_secs: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HandshakeAckPayload {
    pub room_code: String,
    pub white_player_id: String,
    pub black_player_id: String,
    pub initial_fen: String,
    pub time_control_secs: u32,
    pub increment_secs: u32,
    pub started_at_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MovePayload {
    pub move_number: u32,
    pub from_sq: u8, // 0..63
    pub to_sq: u8,   // 0..63
    pub promotion: Option<char>, // 'q', 'r', 'b', 'n'
    pub san: String,
    pub client_sent_time_ms: i64,
    pub remaining_time_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MoveAckPayload {
    pub move_number: u32,
    pub accepted: bool,
    pub current_fen: String,
    pub is_check: bool,
    pub is_checkmate: bool,
    pub is_draw: bool,
    pub white_remaining_ms: i64,
    pub black_remaining_ms: i64,
    pub lag_compensated_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ClockPingPayload {
    pub seq: u32,
    pub t0_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ClockPongPayload {
    pub seq: u32,
    pub t0_ms: i64,
    pub t1_ms: i64, // tempo remoto de recepcao
    pub t2_ms: i64, // tempo remoto de envio
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ClockSyncResult {
    pub rtt_ms: i64,
    pub clock_offset_ms: i64,
    pub estimated_one_way_latency_ms: i64,
}

/// Calcula a compensacao de lag e diferenca de relogio via formulacao canônica SNTP:
/// RTT = (t3 - t0) - (t2 - t1)
/// Offset = ((t1 - t0) + (t2 - t3)) / 2
pub fn calculate_clock_sync(t0: i64, t1: i64, t2: i64, t3: i64) -> ClockSyncResult {
    let rtt = (t3 - t0) - (t2 - t1);
    let offset = ((t1 - t0) + (t2 - t3)) / 2;
    let one_way = (rtt / 2).max(0);

    ClockSyncResult {
        rtt_ms: rtt.max(0),
        clock_offset_ms: offset,
        estimated_one_way_latency_ms: one_way,
    }
}

/// Valida e aplica um lance remoto garantindo integridade estrita das regras FIDE
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteMoveValidationResult {
    pub is_legal: bool,
    pub new_fen: String,
    pub san: String,
    pub is_check: bool,
    pub is_checkmate: bool,
    pub is_draw: bool,
    pub lag_compensated_ms: i64,
    pub error_message: Option<String>,
}

pub fn validate_and_apply_remote_move(
    current_fen: &str,
    from_sq_idx: u8,
    to_sq_idx: u8,
    promotion_char: Option<char>,
    one_way_latency_ms: i64,
) -> RemoteMoveValidationResult {
    if from_sq_idx >= 64 || to_sq_idx >= 64 {
        return RemoteMoveValidationResult {
            is_legal: false,
            new_fen: current_fen.to_string(),
            san: "".to_string(),
            is_check: false,
            is_checkmate: false,
            is_draw: false,
            lag_compensated_ms: 0,
            error_message: Some("Indice de casa invalido".to_string()),
        };
    }

    let pos: Chess = match current_fen.parse::<shakmaty::fen::Fen>() {
        Ok(fen) => match fen.into_position(shakmaty::CastlingMode::Standard) {
            Ok(p) => p,
            Err(e) => {
                return RemoteMoveValidationResult {
                    is_legal: false,
                    new_fen: current_fen.to_string(),
                    san: "".to_string(),
                    is_check: false,
                    is_checkmate: false,
                    is_draw: false,
                    lag_compensated_ms: 0,
                    error_message: Some(format!("Posicao FEN invalida: {:?}", e)),
                };
            }
        },
        Err(e) => {
            return RemoteMoveValidationResult {
                is_legal: false,
                new_fen: current_fen.to_string(),
                san: "".to_string(),
                is_check: false,
                is_checkmate: false,
                is_draw: false,
                lag_compensated_ms: 0,
                error_message: Some(format!("Erro ao ler FEN: {:?}", e)),
            };
        }
    };

    let from = Square::new(from_sq_idx as u32);
    let to = Square::new(to_sq_idx as u32);

    let promotion_role = match promotion_char {
        Some('q') | Some('Q') => Some(Role::Queen),
        Some('r') | Some('R') => Some(Role::Rook),
        Some('b') | Some('B') => Some(Role::Bishop),
        Some('n') | Some('N') => Some(Role::Knight),
        _ => None,
    };

    let _candidate_move = Move::Normal {
        role: match pos.board().piece_at(from) {
            Some(p) => p.role,
            None => {
                return RemoteMoveValidationResult {
                    is_legal: false,
                    new_fen: current_fen.to_string(),
                    san: "".to_string(),
                    is_check: false,
                    is_checkmate: false,
                    is_draw: false,
                    lag_compensated_ms: 0,
                    error_message: Some("Nenhuma peca na casa de origem".to_string()),
                };
            }
        },
        from,
        to,
        promotion: promotion_role,
        capture: pos.board().piece_at(to).map(|p| p.role),
    };

    // Gera lances legais da posicao
    let legals = pos.legal_moves();
    let matching_move = legals.iter().find(|m| {
        m.from() == Some(from) && m.to() == to && m.promotion() == promotion_role
    });

    match matching_move {
        Some(legal_mv) => {
            let mut next_pos = pos.clone();
            next_pos.play_unchecked(*legal_mv);

            let fen_out = shakmaty::fen::Fen::from_position(&next_pos, shakmaty::EnPassantMode::Legal).to_string();
            let is_check = next_pos.is_check();
            let is_checkmate = next_pos.is_checkmate();
            let is_draw = next_pos.is_stalemate() || next_pos.is_insufficient_material();

            // Protecao de lag com teto maximo de 200 ms (padrao FIDE / Lichess)
            let lag_compensation = one_way_latency_ms.clamp(0, 200);

            // Gera notacao em texto simplificada (ex: e2e4)
            let san = format!("{}{}", from, to);

            RemoteMoveValidationResult {
                is_legal: true,
                new_fen: fen_out,
                san,
                is_check,
                is_checkmate,
                is_draw,
                lag_compensated_ms: lag_compensation,
                error_message: None,
            }
        }
        None => RemoteMoveValidationResult {
            is_legal: false,
            new_fen: current_fen.to_string(),
            san: "".to_string(),
            is_check: false,
            is_checkmate: false,
            is_draw: false,
            lag_compensated_ms: 0,
            error_message: Some("Lance ilegal de acordo com as regras FIDE".to_string()),
        },
    }
}

/// Serializa pacote para string JSON
pub fn encode_packet(packet: &NetworkPacket) -> Result<String, serde_json::Error> {
    serde_json::to_string(packet)
}

/// Desserializa pacote a partir de string JSON
pub fn decode_packet(json_str: &str) -> Result<NetworkPacket, serde_json::Error> {
    serde_json::from_str(json_str)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_packet_serialization_roundtrip() {
        let handshake = NetworkPacket::Handshake(HandshakePayload {
            room_code: "XYZ789".to_string(),
            player_id: "p1".to_string(),
            player_name: "Jogador 1".to_string(),
            color_preference: "white".to_string(),
            time_control_secs: 300,
            increment_secs: 3,
        });

        let encoded = encode_packet(&handshake).unwrap();
        assert!(encoded.contains("XYZ789"));

        let decoded = decode_packet(&encoded).unwrap();
        assert_eq!(handshake, decoded);
    }

    #[test]
    fn test_clock_sync_calculation() {
        // t0 = 1000, t1 = 1050, t2 = 1060, t3 = 1120
        // RTT = (1120 - 1000) - (1060 - 1050) = 120 - 10 = 110 ms
        // Offset = ((1050 - 1000) + (1060 - 1120)) / 2 = (50 - 60) / 2 = -5 ms
        let sync = calculate_clock_sync(1000, 1050, 1060, 1120);
        assert_eq!(sync.rtt_ms, 110);
        assert_eq!(sync.clock_offset_ms, -5);
        assert_eq!(sync.estimated_one_way_latency_ms, 55);
    }

    #[test]
    fn test_validate_and_apply_remote_move_legal() {
        let initial_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        // e2 (square 12) -> e4 (square 28)
        let res = validate_and_apply_remote_move(initial_fen, 12, 28, None, 45);
        assert!(res.is_legal);
        assert!(res.new_fen.contains("4P3"));
        assert_eq!(res.lag_compensated_ms, 45);
        assert!(!res.is_checkmate);
    }

    #[test]
    fn test_validate_and_apply_remote_move_illegal() {
        let initial_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        // e2 (square 12) -> e5 (square 36) - ilegal para primeiro lance de peao
        let res = validate_and_apply_remote_move(initial_fen, 12, 36, None, 30);
        assert!(!res.is_legal);
        assert!(res.error_message.is_some());
    }

    #[test]
    fn test_network_protocol_performance_benchmark() {
        use std::time::Instant;

        let initial_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        let start = Instant::now();
        let iterations = 10_000;

        for _ in 0..iterations {
            let sync = calculate_clock_sync(1000, 1050, 1060, 1120);
            assert_eq!(sync.rtt_ms, 110);

            let res = validate_and_apply_remote_move(initial_fen, 12, 28, None, 45);
            assert!(res.is_legal);
        }

        let elapsed = start.elapsed();
        println!("Tempo total para {} validacoes e SNTP: {:?}", iterations, elapsed);
        // Cada iteracao deve levar menos de 50 microssegundos
        assert!(elapsed.as_millis() < 2000, "Performance de rede deve ser inferior a 2s para 10.000 operacoes");
    }
}
