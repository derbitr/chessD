use serde::{Deserialize, Serialize};
use std::io::{Read, Write};

/// Representação binária compacta de lance (16 bits):
/// - bits 0..5: casa de origem (0..63)
/// - bits 6..11: casa de destino (0..63)
/// - bits 12..15: promoção (0 = nenhuma, 1 = q, 2 = r, 3 = b, 4 = n)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CompactMove(pub u16);

impl CompactMove {
    pub fn new(from: u8, to: u8, promo: u8) -> Self {
        let val = (from as u16 & 0x3F) | ((to as u16 & 0x3F) << 6) | ((promo as u16 & 0x0F) << 12);
        Self(val)
    }

    pub fn from_sq(&self) -> u8 {
        (self.0 & 0x3F) as u8
    }

    pub fn to_sq(&self) -> u8 {
        ((self.0 >> 6) & 0x3F) as u8
    }

    pub fn promotion(&self) -> u8 {
        ((self.0 >> 12) & 0x0F) as u8
    }

    pub fn to_uci(&self) -> String {
        let from_file = (self.from_sq() % 8) + b'a';
        let from_rank = (self.from_sq() / 8) + b'1';
        let to_file = (self.to_sq() % 8) + b'a';
        let to_rank = (self.to_sq() / 8) + b'1';

        let mut s = format!(
            "{}{}{}{}",
            from_file as char, from_rank as char, to_file as char, to_rank as char
        );
        match self.promotion() {
            1 => s.push('q'),
            2 => s.push('r'),
            3 => s.push('b'),
            4 => s.push('n'),
            _ => {}
        }
        s
    }

    pub fn from_uci(uci: &str) -> Option<Self> {
        if uci.len() < 4 {
            return None;
        }
        let bytes = uci.as_bytes();
        let from_f = bytes[0].checked_sub(b'a')?;
        let from_r = bytes[1].checked_sub(b'1')?;
        let to_f = bytes[2].checked_sub(b'a')?;
        let to_r = bytes[3].checked_sub(b'1')?;

        if from_f > 7 || from_r > 7 || to_f > 7 || to_r > 7 {
            return None;
        }

        let from = from_r * 8 + from_f;
        let to = to_r * 8 + to_f;
        let promo = if uci.len() >= 5 {
            match bytes[4] {
                b'q' => 1,
                b'r' => 2,
                b'b' => 3,
                b'n' => 4,
                _ => 0,
            }
        } else {
            0
        };

        Some(Self::new(from, to, promo))
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct PuzzleRecord {
    pub id: u32,
    pub fen: String,
    pub moves: Vec<CompactMove>,
    pub rating: u16,
    pub rating_deviation: u16,
    pub themes: String,
}

pub struct ZstdPuzzlePack;

impl ZstdPuzzlePack {
    /// Serializa uma coleção de quebra-cabeças e comprime usando Zstandard
    pub fn compress_puzzles(puzzles: &[PuzzleRecord]) -> Result<Vec<u8>, String> {
        let json_bytes = serde_json::to_vec(puzzles).map_err(|e| format!("Erro JSON: {:?}", e))?;
        let mut encoder = zstd::stream::Encoder::new(Vec::new(), 9).map_err(|e| format!("Erro zstd encoder: {:?}", e))?;
        encoder.write_all(&json_bytes).map_err(|e| format!("Erro escrita zstd: {:?}", e))?;
        let compressed = encoder.finish().map_err(|e| format!("Erro finish zstd: {:?}", e))?;
        Ok(compressed)
    }

    /// Descompacta bytes zstandard para a coleção original de quebra-cabeças
    pub fn decompress_puzzles(compressed: &[u8]) -> Result<Vec<PuzzleRecord>, String> {
        let mut decoder = zstd::stream::Decoder::new(compressed).map_err(|e| format!("Erro zstd decoder: {:?}", e))?;
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed).map_err(|e| format!("Erro leitura zstd: {:?}", e))?;
        let puzzles: Vec<PuzzleRecord> = serde_json::from_slice(&decompressed).map_err(|e| format!("Erro decode JSON: {:?}", e))?;
        Ok(puzzles)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compact_move_encoding_and_uci_roundtrip() {
        // e2e4 -> e2=12, e4=28
        let m = CompactMove::from_uci("e2e4").expect("e2e4");
        assert_eq!(m.to_uci(), "e2e4");
        assert_eq!(m.promotion(), 0);

        // e7e8q promoção
        let promo_m = CompactMove::from_uci("e7e8q").expect("e7e8q");
        assert_eq!(promo_m.to_uci(), "e7e8q");
        assert_eq!(promo_m.promotion(), 1);
    }

    #[test]
    fn test_zstd_compression_and_decompression_lossless() {
        let puzzles = vec![
            PuzzleRecord {
                id: 1001,
                fen: "r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1n3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1".to_string(),
                moves: vec![CompactMove::from_uci("h5f7").unwrap()],
                rating: 800,
                rating_deviation: 50,
                themes: "mate,mateIn1,oneMove".to_string(),
            },
            PuzzleRecord {
                id: 1002,
                fen: "r1b1k2r/pppp1ppp/8/8/1b1nP3/8/PPP2PPP/RNB1KB1R w KQkq - 0 1".to_string(),
                moves: vec![
                    CompactMove::from_uci("c2c3").unwrap(),
                    CompactMove::from_uci("d4c2").unwrap(),
                ],
                rating: 1250,
                rating_deviation: 45,
                themes: "fork,tactics".to_string(),
            },
        ];

        let compressed = ZstdPuzzlePack::compress_puzzles(&puzzles).expect("Compressão");
        assert!(!compressed.is_empty());

        let restored = ZstdPuzzlePack::decompress_puzzles(&compressed).expect("Descompressão");
        assert_eq!(puzzles, restored);
    }
}
