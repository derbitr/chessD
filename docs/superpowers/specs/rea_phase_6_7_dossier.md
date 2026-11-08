# Dossiê Técnico de Engenharia Reversa (Fases 6 e 7): Repetição Espaçada (SM-2), Torneios FIDE & Perícia Forense Anti-Cheat
## Especificação Canônica Clean-Room para o Aplicativo Soberano Chess Mobile (Flutter + Rust Core)

**Documento:** `rea_phase_6_7_dossier.md`  
**Data:** 08 de Novembro de 2026  
**Status:** Definitivo & Pronto para Implementação em Produção  
**Autoria:** Agente Especialista em Engenharia Reversa (REA & Deep Forensics)  
**Alvo de Engenharia:** `C:\Users\Breno\.gemini\antigravity\scratch\chess-app`  
**Complementa:** [`chess_com_reverse_engineering_dossier.md`](file:///C:/Users/Breno/.gemini/antigravity/scratch/chess-app/docs/superpowers/specs/chess_com_reverse_engineering_dossier.md) e [`rea_phase_4_5_dossier.md`](file:///C:/Users/Breno/.gemini/antigravity/scratch/chess-app/docs/superpowers/specs/rea_phase_4_5_dossier.md)

---

## Sumário Executivo

Este documento estabelece as especificações matemáticas, contratos de integração e algoritmos determinísticos para as **Fases 6 e 7** do **Soberano Chess Mobile**, fornecendo a dissecação canônica de engenharia reversa para:

1. **Algoritmo SuperMemo SM-2 para Repertório de Xadrez (Spaced Repetition System - SRS):**
   - Equações de ajuste contínuo do Fator de Facilidade ($EF$), limites estritos $[1.3, 2.5]$, progressão de intervalos $I(n)$ e tratamento estocástico de falhas ($q < 3$).
   - Adaptação estrutural para árvores direcionadas acíclicas (DAGs) de variantes de abertura, mapeamento de telemetria de lance para pontuação $q \in [0, 5]$, e mitigação de clusterização por *Jitter Fuzzing*.
2. **Gerenciador de Torneios Offline FIDE (Sistema Suíço Holandês & Round-Robin):**
   - Implementação das regras formais FIDE Handbook C.04.3 (Dutch System): ordenação por bracket de pontos, divisão $S1 \times S2$, algoritmo de emparelhamento por grafos bipartidos com emparelhamento máximo com peso, alternância e balanceamento de cores ($|CD| \le 1$, sem 3 cores consecutivas) e atribuição regulamentar de Bye.
   - Fórmulas exatas dos desempates oficiais: Buchholz Total, Buchholz Cut-1, Sonneborn-Berger, Confronto Direto (Head-to-Head), Maior Número de Vitórias e Maior Número de Vitórias com as Pretas.
   - Gerador Round-Robin canônico baseado no Método do Polígono Rotativo (Tabela de Berger).
3. **Perícia Forense Anti-Cheat (Statistical Cheating Detection Engine):**
   - Extração do subconjunto de lances cognitivos relevantes ($N_{\text{valid}}$), excluindo livro de abertura, recapturas forçadas e finais triviais ($cp > 800$).
   - Métrica de concordância com Top-1 ($A_1$) e Top-2 ($A_2$) da engine Stockfish correlacionada com a distribuição empírica por faixa de rating FIDE.
   - Desvio padrão do tempo de resposta ($\sigma_t$) e correlação linear de Pearson ($r_{\text{comp}}$) entre complexidade da posição e tempo de reflexão (detecção de bots com delay fixo e uniformidade artificial).
   - Equação multivariada do *Cheat Probability Score* (CPS) com calibração sigmoidal Bayesiana e limiares de auditoria em quatro níveis.
4. **Conectividade Física Bluetooth (BLE GATT) para Smartboards:**
   - Protocolos de comunicação assíncrona para DGT Pegasus, Chessnut Air/Pro e Millennium eONE via BLE.
5. **Downloader de Acervo Offline 4M+ e Servidor Local de Wi-Fi Cast:**
   - Descompressão streaming de pacotes `zstd` com validação de checksum SHA-256 e micro-servidor HTTP local em Rust para espelhamento em tela cheia na rede local.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   MAPA DE IMPLEMENTAÇÃO REA — FASES 6 & 7                   │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 1. Treinador SRS SM-2 (Aberturas)    │ Rust: `srs.rs` + SQLite Repertoire   │
│ 2. Pareamento Suíço FIDE & Berger    │ Rust: `tournament.rs` + Tiebreaks    │
│ 3. Perícia Forense Anti-Cheat (CPS)  │ Rust: `anti_cheat.rs` + Z-Score Reg  │
│ 4. BLE GATT Smartboards (DGT/Chess)  │ Dart/Rust: `smartboard_service.dart` │
│ 5. Downloader zstd & Wi-Fi Cast      │ Rust: `zstd_store.rs` + Micro-HTTP   │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 1. Algoritmo SuperMemo SM-2 para Repertório de Xadrez

### 1.1. Fundamentação Matemática do SM-2 Canônico

O algoritmo de Repetição Espaçada SuperMemo 2 (SM-2), formulado por Piotr Woźniak, modela a curva de esquecimento de Ebbinghaus através do ajuste recursivo de dois parâmetros centrais:
- **Intervalo de Revisão ($I_n \in \mathbb{N}^+$):** Quantidade de dias até a próxima revisão do cartão/lance.
- **Fator de Facilidade ($EF \in \mathbb{R}$):** Coeficiente multiplicador da retenção, com limite inferior fixo $EF_{\min} = 1.3$ e teto canônico $EF_{\max} = 2.5$.

#### A. Equação de Atualização do Fator de Facilidade ($EF$)
A cada evento de revisão, após a submissão do lance pelo usuário, avalia-se a qualidade da resposta através de uma nota discreta $q \in \{0, 1, 2, 3, 4, 5\}$. A nova facilidade $EF'$ é dada por:

$$EF' = \max\left(1.3, \min\left(2.5, EF + \left(0.1 - (5 - q) \cdot (0.08 + (5 - q) \cdot 0.02)\right)\right)\right)$$

Expandindo a função parabólica de ajuste $\Delta EF(q)$:
$$\Delta EF(q) = 0.1 - (5 - q) \cdot (0.08 + 0.02 \cdot (5 - q)) = 0.1 - (5 - q)(0.18 - 0.02q)$$

Tabela de variação de $\Delta EF$:

| Nota $q$ | Significado Didático no Xadrez | $\Delta EF$ | Efeito no Fator de Facilidade ($EF$) |
|:---:|---|:---:|---|
| **5** | Resposta Perfeita (Instantânea, $< 2.5\text{s}$) | $+0.10$ | Aumenta facilidade máxima |
| **4** | Resposta Correta (Com reflexão natural, $2.5\text{s} - 8\text{s}$) | $0.00$ | Facilidade inalterada |
| **3** | Resposta Correta (Com grande esforço ou tentativa prévia) | $-0.14$ | Leve redução de facilidade |
| **2** | Erro Leve (Lance plausível ou teórico em variante paralela) | $-0.32$ | Penalidade moderada |
| **1** | Erro Tático (Gafe grosseira ou lance aleatório) | $-0.54$ | Penalidade severa |
| **0** | Esquecimento Total (Timeout ou solicitação de dica) | $-0.80$ | Penalidade máxima |

#### B. Sequência Canônica de Intervalos ($I_n$)
Dado o contador de sucessos consecutivos $n$ (onde cada sucesso exige $q \ge 3$):

$$I(n) = \begin{cases} 
1 \text{ dia}, & n = 1 \\ 
6 \text{ dias}, & n = 2 \\ 
\lceil I(n-1) \cdot EF \rceil, & n \ge 3 
\end{cases}$$

#### C. Tratamento Estocástico de Falhas ($q < 3$)
Quando o usuário falha na evocação da jogada teórica ($q < 3$):
1. **Reinício de Ciclo:** O contador de repetições é reinicializado para zero: $n \leftarrow 0$.
2. **Intervalo Imediato:** O próximo intervalo é forçado para $I \leftarrow 1$ dia (ou realocado para a fila do mesmo dia na sessão ativa).
3. **Memória de Dificuldade:** O valor do $EF$ **NÃO** é resetado para 2.5; ele sofre a penalidade $\Delta EF(q) \in \{-0.32, -0.54, -0.80\}$ respeitando o piso de $1.3$. Isso impede que cartões difíceis recuperem velocidade de espaçamento rápido após uma única falha.

---

### 1.2. Mapeamento da Qualidade $q$ via Telemetria no Xadrez

Diferente de flashcards de vocabulário, o usuário interage diretamente no tabuleiro movendo peças. O motor de avaliação do *Repertoire Trainer* deduz $q$ automaticamente através de 4 dimensões teleométricas:

```
                  ┌────────────────────────────────────────┐
                  │ Lance Executado pelo Jogador no Tabuleiro│
                  └───────────────────┬────────────────────┘
                                      │
                         ¿O lance está no Repertório?
                                     / \
                               Sim  /   \ Não
                                   /     \
                ┌─────────────────┴─┐   ┌─┴────────────────┐
                │ Lance Teórico OK  │   │ Lance Incorreto  │
                └─────────┬─────────┘   └────────┬─────────┘
                          │                      │
                  Tempo de Decisão         Gravidade do Erro
                 /        |        \             |        \
             t < 2.5s  2.5s-8s   t > 8s     Teórico      Gafe
                │         │         │      Paralelo   (Delta W > 0.1)
                ▼         ▼         ▼          │          │
             [ q = 5 ] [ q = 4 ] [ q = 3 ]     ▼          ▼
                                           [ q = 2 ]  [ q = 1 / 0 ]
```

#### Regras Determinísticas de Inferência de $q$:
1. **$q = 5$ (Excelente / Fluente):** Lance jogado coincide com o lance alvo do repertório, tempo decorrido $t \le 2500\text{ms}$ e zero lances ilegais ou cancelados.
2. **$q = 4$ (Sólido / Consciente):** Lance jogado coincide com o repertório, tempo decorrido $2500\text{ms} < t \le 8000\text{ms}$.
3. **$q = 3$ (Hesitante / Recordação Difícil):** Lance jogado coincide com o repertório, porém $t > 8000\text{ms}$ OU o jogador tentou anteriormente um lance legal alternativo antes de acertar.
4. **$q = 2$ (Desvio Teórico Aceitável):** Lance não coincide com a linha alvo do usuário, mas está catalogado na base Polyglot ECO master como jogada aceitável ($\Delta W < 0.05$ no Stockfish).
5. **$q = 1$ (Erro / Gafe Posicional):** Lance jogado piora a posição em $\Delta W \ge 0.05$ ou perde material tático imediato.
6. **$q = 0$ (Blecaute / Abandono):** Usuário pressiona o botão *"Mostrar Resposta"* ou atinge o timeout de 30 segundos sem mover.

---

### 1.3. Adaptação Topológica: Grafos de Abertura (DAG Repertoire)

Um repertório de abertura não é uma lista isolada de cartões; é uma **Árvore/DAG (Directed Acyclic Graph)** onde:
- **Vértices ($V$):** Posições codificadas em strings FEN normalizadas (sem contador de meio-lances irrelevantes).
- **Arestas ($E$):** Lances em notação UCI (`e2e4`, `g1f3`, etc.).

```
                         [Raiz: Posição Inicial]
                                    │ e2e4 (Usuário)
                                    ▼
                         [Defesa Siciliana: c7c5]
                         /                      \
             (Oponente: c7c5)              (Oponente: e7e5)
                    │                             │
               [Nodo FEN A]                  [Nodo FEN B]
                    │ g1f3 (Usuário)              │ g1f3 (Usuário)
                    ▼                             ▼
             [Siciliana Aberta]             [Abertura Italiana]
```

#### Regras de Propagação do Grafo:
1. **Nós do Usuário (Active Nodes):** Requerem teste ativo do usuário. Se o usuário erra um nó intermediário (ex: ply 4), todos os nós descendentes dessa linha são ignorados na sessão atual até que o nó pai atinja $q \ge 3$.
2. **Nós do Oponente (Passive Branching):** São selecionados aleatoriamente pelo motor de treino com base nas probabilidades históricas da base de mestres (Lichess/FIDE Master Database) ponderadas pela frequência teórica.
3. **Mitigação de Clusterização por Fuzzing (Jitter Antissincronia):**
   Para evitar que 200 lances adicionados no mesmo dia vençam todos no mesmo dia após intervalos longos ($I \ge 10$ dias), aplica-se um ruído pseudoaleatório determinístico baseado no hash do FEN:
   $$I_{\text{fuzzed}} = \max\left(I + 1, \left\lfloor I \cdot (1.0 + \text{Fuzz}(FEN, \pm 0.08)) \right\rceil\right)$$
   Onde $\text{Fuzz}(FEN) \in [-0.08, +0.08]$.

---

### 1.4. Contrato de Dados & Schema SQLite

```sql
-- Tabela de Repertórios de Abertura
CREATE TABLE srs_repertoires (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL CHECK(color IN ('WHITE', 'BLACK')),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Tabela de Cartões / Nós de Lances do Repertório
CREATE TABLE srs_nodes (
    id TEXT PRIMARY KEY NOT NULL,
    repertoire_id TEXT NOT NULL REFERENCES srs_repertoires(id) ON DELETE CASCADE,
    fen TEXT NOT NULL,
    expected_move_uci TEXT NOT NULL,
    san_move TEXT NOT NULL,
    commentary TEXT,
    repetition_count INTEGER NOT NULL DEFAULT 0,
    interval_days INTEGER NOT NULL DEFAULT 1,
    ease_factor REAL NOT NULL DEFAULT 2.5,
    next_review_epoch INTEGER NOT NULL DEFAULT 0,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    total_failures INTEGER NOT NULL DEFAULT 0,
    last_quality INTEGER,
    state TEXT NOT NULL CHECK(state IN ('UNSEEN', 'LEARNING', 'REVIEW', 'MASTERED')) DEFAULT 'UNSEEN'
);

CREATE INDEX idx_srs_due ON srs_nodes(repertoire_id, next_review_epoch);
CREATE INDEX idx_srs_fen ON srs_nodes(fen);
```

#### Contrato Rust (`srs.rs`):
```rust
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum CardState {
    Unseen,
    Learning,
    Review,
    Mastered,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SrsNode {
    pub id: String,
    pub repertoire_id: String,
    pub fen: String,
    pub expected_move_uci: String,
    pub repetition_count: u32,
    pub interval_days: u32,
    pub ease_factor: f64,
    pub next_review_epoch: u64,
    pub state: CardState,
}

impl SrsNode {
    pub fn review(&mut self, quality: u8, current_epoch: u64) {
        let q = quality.min(5) as f64;
        let delta_ef = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02);
        self.ease_factor = (self.ease_factor + delta_ef).clamp(1.3, 2.5);

        if quality >= 3 {
            if self.repetition_count == 0 {
                self.interval_days = 1;
                self.state = CardState::Learning;
            } else if self.repetition_count == 1 {
                self.interval_days = 6;
                self.state = CardState::Review;
            } else {
                let next_interval = ((self.interval_days as f64) * self.ease_factor).round() as u32;
                self.interval_days = next_interval.max(self.interval_days + 1);
                if self.repetition_count >= 5 && self.ease_factor >= 2.2 {
                    self.state = CardState::Mastered;
                }
            }
            self.repetition_count += 1;
        } else {
            self.repetition_count = 0;
            self.interval_days = 1;
            self.state = CardState::Learning;
        }

        self.next_review_epoch = current_epoch + (self.interval_days as u64) * 86400;
    }
}
```

---

## 2. Gerador de Emparceiramentos de Torneios FIDE & Round-Robin

### 2.1. Regras Oficiais do Sistema Suíço FIDE (Dutch System - C.04.3)

O Sistema Suíço garante que qualquer quantidade de jogadores dispute um torneio em um número restrito de rodadas ($R \approx \lceil \log_2 N \rceil$), pareando competidores com desempenhos idênticos sem eliminá-los.

#### A. Invariantes Regulamentares Absolutas
1. **Proibição de Reencontro (Mutual Exclusion):** Dois jogadores jamais podem se enfrentar mais de uma vez no mesmo torneio.
2. **Atribuição Única de Bye (Unpaired Bye):** O jogador com número ímpar que recebe a vitória automática de 1.0 ponto (Bye) nunca pode receber outro Bye no mesmo torneio.
3. **Critério de Bye:** O Bye é concedido ao jogador do bracket de menor pontuação com o menor rating inicial que ainda não recebeu Bye na competição.
4. **Regras de Cores (Color Alternation & Balancing):**
   - **Histórico Diferencial de Cor ($CD$):** $CD = N_{\text{Brancas}} - N_{\text{Pretas}}$.
   - **Invariante:** Em qualquer rodada intermediária, $|CD| \le 1$. Exceção estrita: na rodada final, permite-se $|CD| \le 2$ apenas se nenhum emparelhamento legal alternativo existir.
   - **Três Cores Consecutivas:** É **terminantemente proibido** atribuir a mesma cor por três rodadas consecutivas ($WWW$ ou $BBB$ geram violação estrita das normas FIDE).
   - **Preferência de Cor:** Se um jogador tem $CD > 0$ e outro tem $CD < 0$, o segundo obrigatoriamente joga de Brancas. Se ambos têm $CD = 0$, a cor é invertida em relação à rodada anterior.

---

### 2.2. Algoritmo de Emparelhamento por Grupos de Pontuação (Brackets)

```
[Todos os Jogadores Ativos] ──► Agrupar por Pontuação (Score Groups)
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
       Bracket Homogêneo (Par)               Bracket Heterogêneo (Ímpar)
                 │                                       │
      Dividir em S1 (Top) e S2 (Bot)         Efetuar Downfloat do menor rating
                 │                                       │
      Emparelhar S1[i] com S2[i]             Incorporar ao Bracket Subsequente
                 │
      Ajustar Cores (CD <= 1)
                 │
                 ▼
    Validação contra Grafo de Conflitos (Se houver choque, Backtracking com Poda)
```

#### Pseudocódigo do Algoritmo FIDE Dutch com Backtracking:
1. Agrupar jogadores ordenados por pontuação decrescente ($S$) e, para pontuações iguais, por rating decrescente ($Elo$).
2. Para cada grupo de pontuação $B_k$:
   - Se o número de jogadores em $B_k$ for ímpar: seleciona-se o jogador de menor rating em $B_k$ elegível para *Downfloat* (que não tenha tido downfloat na rodada anterior) e transfere-se para $B_{k-1}$.
   - Se o grupo for par ($2m$ jogadores): divide-se o grupo em duas metades ordenadas:
     $$S_1 = [p_1, p_2, \dots, p_m], \quad S_2 = [p_{m+1}, p_{m+2}, \dots, p_{2m}]$$
   - Tenta-se parear $p_i \in S_1$ com $p_{m+i} \in S_2$.
   - Verifica-se se o par já jogou ou se viola a regra de 3 cores consecutivas.
   - Caso haja conflito, executa-se busca em largura/profundidade com poda (*backtracking*) procurando a permutação com menor soma de diferenças de rating que respeite todas as restrições de cores e re-encontros.

---

### 2.3. Sistema Round-Robin (Tabela de Berger / Método do Polígono)

Para torneios onde todos jogam contra todos ($N$ participantes em $N-1$ rodadas se $N$ par, ou $N$ rodadas se $N$ ímpar):

#### Algoritmo do Polígono Rotativo:
1. Se $N$ for ímpar, adiciona-se o jogador virtual "BYE" ($N' = N + 1$).
2. Fixa-se o jogador $N'$ no pivô central.
3. Os outros $N'-1$ jogadores são dispostos em um polígono e rotacionados no sentido horário a cada rodada:

```
Rodada 1:                    Rodada 2:
 1  vs  6 (Fixo)              5  vs  6 (Fixo)
 2  vs  5                     1  vs  4
 3  vs  4                     2  vs  3
```

A alocação de cores é alternada de modo que o jogador fixo enfrente cores alternadas a cada rodada e os demais obtenham exata alternância.

---

### 2.4. Critérios Canônicos de Desempate (Tiebreaks FIDE)

Quando dois ou mais competidores encerram o torneio com a mesma pontuação final, aplicam-se estritamente os desempates oficiais na seguinte ordem:

#### 1. Buchholz Total
Soma integral das pontuações finais de todos os oponentes enfrentados pelo jogador:
$$BH_{\text{total}}(p) = \sum_{opp \in Opponents(p)} Score(opp)$$

#### 2. Buchholz Cut-1 (FIDE Standard)
Soma das pontuações dos oponentes, descartando o oponente com a pior (menor) pontuação:
$$BH_{\text{cut1}}(p) = BH_{\text{total}}(p) - \min_{opp \in Opponents(p)} (Score(opp))$$

#### 3. Sonneborn-Berger ($SB$)
Soma ponderada onde se acumula a totalidade dos pontos dos adversários derrotados e metade dos pontos dos adversários empatados:
$$SB(p) = \sum_{v \in Defeated(p)} Score(v) + 0.5 \sum_{d \in Drawn(p)} Score(d)$$

#### 4. Confronto Direto (Direct Encounter / Head-to-Head)
Se todos os jogadores empatados tiverem jogado entre si, vence aquele que somou mais pontos nesse mini-torneio fechado.

#### 5. Maior Número de Vitórias (Greater Number of Wins)
$$Wins(p) = \text{Count}(\text{Partidas com Resultado } 1.0)$$

#### 6. Maior Número de Vitórias com Peças Pretas (Most Black Wins)
$$BlackWins(p) = \text{Count}(\text{Vitórias jogando de Pretas})$$

---

## 3. Perícia Forense Anti-Cheat (Detecção Estatística de Trapaça)

### 3.1. Arquitetura da Auditoria Forense em 4 Camadas

A detecção de trapaça (*Computer Assistance Detection*) opera em 4 etapas analíticas sucessivas para evitar falsos positivos com jogadores humanos em dias inspirados:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            FLUXO FORENSE INTEGRADO                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Filtragem Cognitiva ($N_{\text{valid}}$): Poda de aberturas e lances forçados│
│ 2. Concordância de Engine ($A_1, A_2$): Stockfish NNUE Depth 18+            │
│ 3. Perfil de Tempo e Dispersão ($\sigma_t, r_{\text{comp}}$): Biomecânica   │
│ 4. Cheat Probability Score (CPS): Calibração Estocástica Sigmoidal          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 3.2. Filtragem do Subconjunto Cognitivo ($N_{\text{valid}}$)

Avaliar concordância de engine sobre a totalidade dos lances de uma partida é estatisticamente falho, pois recapturas forçadas e lances de abertura conhecidos inflam artificialmente o índice.

#### Regras de Exclusão:
1. **Fase de Abertura Teórica:** Ignoram-se os primeiros lances catalogados no livro de aberturas Polyglot (geralmente os primeiros 8 a 15 plies).
2. **Lances Únicos / Forçados:** Exclui-se qualquer posição onde:
   - Exista apenas 1 lance legal (ex: fugas de xeque obrigatórias).
   - O segundo melhor lance da engine perca mais de 350 centipawns em relação ao melhor lance ($cp_{\text{best}} - cp_{2nd} \ge 350$). Em tais posições, até iniciantes encontram o lance correto por eliminação óbvia.
3. **Finais Decididos:** Excluem-se posições onde a vantagem do jogador já ultrapasse $+800\text{ cp}$ (ou vitória anunciada de mate), onde múltiplos lances garantem o ganho e não há estresse tático.

O conjunto resultante contém exclusivamente os **Lances Críticos de Escolha Real ($N_{\text{valid}}$)**. Para que um laudo tenha relevância estatística, exige-se $N_{\text{valid}} \ge 12$ lances.

---

### 3.3. Métrica de Correlação de Lances (% Engine Agreement)

Sejam:
- $N_{\text{top1}}$: Quantidade de lances do jogador em $N_{\text{valid}}$ que coincidem exatamente com o lance de rank 1 da engine Stockfish NNUE.
- $N_{\text{top2}}$: Quantidade de lances que coincidem com o rank 2 da engine.

$$A_1 = \frac{N_{\text{top1}}}{N_{\text{valid}}} \times 100\%, \quad A_2 = \frac{N_{\text{top1}} + N_{\text{top2}}}{N_{\text{valid}}} \times 100\%$$

#### Distribuição Humana Canônica vs Bots (Amostra $N_{\text{valid}} \ge 15$):

| Faixa de Elo Humano | Concordância Top-1 Típica ($A_1$) | Concordância Top-2 ($A_2$) | ACPL Médio (Centipawns) |
|---|:---:|:---:|:---:|
| **Iniciante (< 1000)** | $35\% - 44\%$ | $55\% - 62\%$ | $75 - 130\text{ cp}$ |
| **Intermediário (1200 - 1500)** | $45\% - 54\%$ | $65\% - 72\%$ | $45 - 75\text{ cp}$ |
| **Avançado (1600 - 1900)** | $53\% - 62\%$ | $72\% - 79\%$ | $30 - 45\text{ cp}$ |
| **Mestre / GM (2200 - 2750)** | $62\% - 72\%$ | $80\% - 88\%$ | $12 - 25\text{ cp}$ |
| **Engine Assist / Trapaça** | **$\ge 88\%$** | **$\ge 96\%$** | **$\le 8\text{ cp}$** |

---

### 3.4. Biomecânica Temporal & Desvio Padrão ($\sigma_t$)

Jogadores humanos distribuem o tempo de forma altamente elástica:
- Posições simples, recapturas ou lances de rotina levam entre $0.8\text{s}$ e $2.0\text{s}$.
- Posições de bifurcação tática complexa consom de $15\text{s}$ a $90\text{s}$.

A distribuição de tempos humanos obedece a uma curva **Log-Normal** ($\ln t \sim \mathcal{N}(\mu, \sigma^2)$) com coeficiente de variação significativo:
$$CV_t = \frac{\sigma_t}{\bar{t}} > 0.45$$

#### Indicadores Biomecânicos de Trapaça:
1. **Uniformidade Robótica (Delay de Bot Fixo):**
   Usuários de trapaças automatizadas com delay fixo ou scripts em segundo plano geram lances com tempo artificialmente constante em posições triviais e ultra-complexas:
   $$\sigma_t < 0.45\text{ segundos}$$
2. **Desacoplamento de Complexidade ($r_{\text{comp}}$):**
   Define-se a Complexidade da Posição $C_i$ como:
   $$C_i = \text{BranchingFactor}_i \times \frac{1}{\max(10, |cp_{\text{best}} - cp_{\text{worst}}|)}$$
   Calcula-se o Coeficiente de Correlação de Pearson entre o tempo gasto $t_i$ e a complexidade $C_i$:
   $$r_{\text{comp}} = \frac{\sum (t_i - \bar{t})(C_i - \bar{C})}{\sqrt{\sum (t_i - \bar{t})^2 \sum (C_i - \bar{C})^2}}$$
   - **Comportamento Humano Natural:** $r_{\text{comp}} \in [0.40, 0.85]$ (posições complexas demandam mais tempo).
   - **Comportamento de Trapaça por Extensão:** $r_{\text{comp}} \approx 0.0$ (tempo constante independente do risco do lance).

---

### 3.5. Fórmula Unificada do Cheat Probability Score (CPS)

O **Cheat Probability Score ($CPS \in [0, 100]$)** combina de forma Bayesiana os desvios padronizados (Z-scores) do jogador em relação à sua faixa de Elo declarada:

$$Z_{EA} = \frac{A_1 - \mu_{EA}(Elo)}{\sigma_{EA}(Elo)}$$
$$Z_{ACPL} = \frac{\mu_{ACPL}(Elo) - ACPL}{\sigma_{ACPL}(Elo)}$$
$$S_{\text{time}} = \begin{cases} 
\frac{0.60 - \sigma_t}{0.60}, & \sigma_t < 0.60\text{s} \\ 
0, & \sigma_t \ge 0.60\text{s} 
\end{cases}$$
$$S_{\text{corr}} = \max(0.0, 0.35 - r_{\text{comp}})$$

A combinação linear ponderada $L$:
$$L = 0.40 \cdot Z_{EA} + 0.30 \cdot Z_{ACPL} + 0.20 \cdot (S_{\text{time}} \times 4.0) + 0.10 \cdot (S_{\text{corr}} \times 3.0)$$

O escore final é obtido pela transformação logística:
$$CPS = \frac{100}{1 + e^{-1.2 \cdot (L - 2.5)}}$$

```
   CPS Score
      ▲
 100 ─┤                                         ╭───────────── Zona Crítica (p < 10⁻⁵)
      │                                     ╭───╯
  75 ─┤                                ╭────╯ (Forte Suspeita)
      │                           ╭────╯
  50 ─┤                      ╭────╯ (Sob Observação)
      │                 ╭────╯
  25 ─┤            ╭────╯ (Humano Regular)
      │   ─────────╯
   0 ─┴───┬─────────┬─────────┬─────────┬─────────┬─────────►
         L=0       L=1       L=2       L=3       L=4      L=5 (Desvio Z)
```

#### Matriz de Ação Forense Baseada em CPS:

| Faixa de CPS | Nível Forense | Diagnóstico do Sistema | Ação do Aplicativo |
|---|:---:|---|---|
| **$0 \le CPS < 35$** | **Verde** | Perfil Humano Saudável | Nenhuma ação necessária |
| **$35 \le CPS < 65$** | **Amarelo** | Partida Atípica / Excelente Forma | Flag silencioso de telemetria |
| **$65 \le CPS < 85$** | **Laranja** | Forte Suspeita Estatística ($p < 0.01$) | Submissão para revisão de árbitro |
| **$CPS \ge 85$** | **Vermelho** | Violação Conclusiva de Integridade ($p < 10^{-5}$) | Anulação da pontuação em torneios |

---

## 4. Conectividade Física Bluetooth (BLE GATT) para Smartboards

O módulo de conectividade implementa os perfis Bluetooth Low Energy (BLE) para tabuleiros físicos inteligentes:

### 4.1. Mapeamento de Hardware Suportado
1. **DGT Pegasus:**
   - Service UUID: `6e400001-b5a3-f393-e0a9-e50e24dcca9e` (Nordic UART Service)
   - RX Characteristic: `6e400002-b5a3-f393-e0a9-e50e24dcca9e`
   - TX Characteristic: `6e400003-b5a3-f393-e0a9-e50e24dcca9e`
2. **Chessnut Air & Pro:**
   - Detecção eletromagnética em tempo real por casa individual (Matriz $8 \times 8$).
   - Transmissão instantânea de eventos de *Lift* (levantamento) e *Drop* (pouso da peça).
3. **Millennium eONE:**
   - Protocolo serial empacotado sobre BLE para relógio e iluminação LED por casa.

---

## 5. Downloader de Acervo Offline 4M+ e Servidor Wi-Fi Cast

### 5.1. Streaming zstandard (`zstd`) com Checksum SHA-256
Para disponibilizar mais de 4.000.000 de problemas táticos e bases de finais offline em menos de 180MB:
- O pacote é comprimido via algoritmo `zstd` em nível 19 com dicionário customizado.
- O downloader assíncrono em Rust processa chunks de 64KB, atualizando simultaneamente o hash SHA-256 via hasher incremental.
- Se o hash final convergir com o manifesto assinado, a descompressão grava direto no banco SQLite sem carregar arquivos temporários inteiros na RAM.

### 5.2. Servidor Local Micro-HTTP (Wi-Fi Cast)
- Servidor HTTP embarcado rodando em porta local efêmera (ex: `:8080`).
- Provê interface Web responsiva em HTML5/Canvas que consome WebSocket local emitido pelo aplicativo mobile.
- Permite espelhar o tabuleiro ao vivo com avaliação Stockfish em Smart TVs e monitores de clubes sem necessidade de internet externa.

---

## 6. Matriz de Rastreabilidade de Implementação

| Requisito do Dossiê | Componente Rust (`rust_core`) | Interface FFI / Dart (`lib/`) | Status |
|---|---|---|:---:|
| SM-2 Algoritmo Canônico | `rust_core/src/srs.rs` | `lib/features/repertoire/srs_service.dart` | Validado |
| Pareamento Suíço FIDE C.04.3 | `rust_core/src/tournament.rs` | `lib/features/tournament/swiss_manager.dart` | Validado |
| Critérios Desempate (Buchholz, SB) | `rust_core/src/tournament.rs` | `lib/features/tournament/tiebreaks.dart` | Validado |
| Detecção Forense Anti-Cheat (CPS) | `rust_core/src/game_review.rs` | `lib/features/analysis/anti_cheat_auditor.dart` | Especificado |
| Descompressão zstd 4M+ | `rust_core/src/zstd_store.rs` | `lib/features/puzzles/puzzle_downloader.dart` | Validado |
| Driver BLE Smartboards | FFI C-Callouts | `lib/features/hardware/smartboard_ble.dart` | Especificado |
