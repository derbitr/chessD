class LessonExercise {
  final String id;
  final String title;
  final String instruction;
  final String initialFen;
  final List<String> solutionUciMoves;
  final String hint;

  const LessonExercise({
    required this.id,
    required this.title,
    required this.instruction,
    required this.initialFen,
    required this.solutionUciMoves,
    required this.hint,
  });
}

class LessonStep {
  final String id;
  final String title;
  final String shortTheory;
  final String demonstrationFen;
  final List<LessonExercise> exercises;
  final int starsReward;

  const LessonStep({
    required this.id,
    required this.title,
    required this.shortTheory,
    required this.demonstrationFen,
    required this.exercises,
    this.starsReward = 3,
  });
}

class LessonModule {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final List<LessonStep> steps;

  const LessonModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.steps,
  });

  /// Currículo Canônico Extensivo da Trilha de Maestria
  static List<LessonModule> getCuratedCurriculum() {
    return const [
      // MÓDULO 1: FUNDAMENTOS DO TABULEIRO
      LessonModule(
        id: 'mod_1_fundamentals',
        title: 'Módulo 1: Fundamentos do Tabuleiro',
        description: 'Domínio das peças, movimentação geométrica e mates essenciais.',
        iconName: 'flag',
        steps: [
          LessonStep(
            id: 'step_1_1_checkmate',
            title: 'O que é o Xeque-Mate',
            shortTheory:
                'O xeque-mate acontece quando o Rei inimigo está sob ataque direto e não existe nenhuma forma legal de fugir, bloquear com outra peça ou capturar o atacante.',
            demonstrationFen: 'r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1n3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_1_1_1',
                title: 'Mate do Pastor',
                instruction: 'As Brancas têm um mate em 1 lance visando a casa fraca f7. Encontre o golpe final!',
                initialFen: 'r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1n3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1',
                solutionUciMoves: ['h5f7'],
                hint: 'A Rainha e o Bispo cooperam diretamente contra o peão de f7.',
              ),
              LessonExercise(
                id: 'ex_1_1_2',
                title: 'Mate da Escadinha',
                instruction: 'Com a torre em a7 cortando a sétima fila, suba a outra torre para a oitava fila e aplique o mate!',
                initialFen: '4k3/R7/8/8/8/8/8/1R4K1 w - - 0 1',
                solutionUciMoves: ['b1b8'],
                hint: 'A torre de a7 corta a fuga em e7 e a torre de b1 aplica o xeque mortal em b8.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_1_2_castling',
            title: 'O Roque e a Segurança do Rei',
            shortTheory:
                'O roque é o único lance onde você move duas peças ao mesmo tempo. Ele protege o seu Rei e coloca a Torre em jogo ativo.',
            demonstrationFen: 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_1_2_1',
                title: 'Roque Curto',
                instruction: 'Garanta a segurança do seu Rei fazendo o roque curto nas alas do rei.',
                initialFen: 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1',
                solutionUciMoves: ['e1g1'],
                hint: 'Mova o rei duas casas em direção à torre de h1 (e1 para g1).',
              ),
            ],
          ),
          LessonStep(
            id: 'step_1_3_knight',
            title: 'O Salto e Domínio do Cavalo',
            shortTheory:
                'O cavalo é a única peça capaz de pular sobre outras peças. Ele salta em formato de L e é mortal em postos avançados.',
            demonstrationFen: '4k3/8/8/3p4/4N3/8/8/4K3 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_1_3_1',
                title: 'Cavalo Ofensivo com Xeque',
                instruction: 'Salte com o cavalo dando xeque no rei adversário e controlando o centro.',
                initialFen: '4k3/8/8/3p4/4N3/8/8/4K3 w - - 0 1',
                solutionUciMoves: ['e4f6'],
                hint: 'Salte de e4 para f6 ameaçando o rei inimigo.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_1_4_bishop_pair',
            title: 'O Poder das Diagonais do Bispo',
            shortTheory:
                'Bispos operam em longas diagonais abertas. Posicione seus bispos mirando pontos vulneráveis do roque adversário.',
            demonstrationFen: 'r1bqk2r/pppp1ppp/2n5/2b1p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_1_4_1',
                title: 'Bispo Ativo em c4',
                instruction: 'Desenvolva o bispo para c4 visando o ponto fraco em f7.',
                initialFen: 'r1bqk2r/pppp1ppp/2n5/2b1p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1',
                solutionUciMoves: ['f1c4'],
                hint: 'Desenvolva o bispo de casas claras para c4.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 2: TÁTICAS ELEMENTARES
      LessonModule(
        id: 'mod_2_tactics',
        title: 'Módulo 2: Táticas Elementares',
        description: 'Garfos, cravadas, espetos e ataques descobertos.',
        iconName: 'bolt',
        steps: [
          LessonStep(
            id: 'step_2_1_fork',
            title: 'O Garfo Real do Cavalo',
            shortTheory:
                'Um garfo acontece quando uma única peça ataca simultaneamente dois alvos inimigos de valor superior.',
            demonstrationFen: 'r3k3/ppp2ppp/8/3N4/8/8/PPP2PPP/4K3 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_2_1_1',
                title: 'Garfo Fatal em c7',
                instruction: 'Capture o peão de c7 com o cavalo, aplicando xeque no rei e atacando a torre em a8 simultaneamente!',
                initialFen: 'r3k3/ppp2ppp/8/3N4/8/8/PPP2PPP/4K3 w - - 0 1',
                solutionUciMoves: ['d5c7'],
                hint: 'O cavalo salta de d5 para c7 capturando o peão e dando garfo real.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_2_2_pin',
            title: 'A Cravada Absoluta',
            shortTheory:
                'Uma peça está sob cravada absoluta quando não pode se mover porque isso exporia diretamente o seu Rei a um xeque ilegal.',
            demonstrationFen: 'r1bqk2r/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_2_2_1',
                title: 'Ataque à Peça Cravada',
                instruction: 'O cavalo preto de c6 está cravado no rei pelo bispo em b5. Avance seu peão de d4 e ganhe material!',
                initialFen: 'r1bqk2r/pppp1ppp/2n5/1B2p3/3PP3/5N2/PPP2PPP/RNBQK2R w KQkq - 0 1',
                solutionUciMoves: ['d4d5'],
                hint: 'Ataque a peça cravada com o peão (d4 para d5).',
              ),
            ],
          ),
          LessonStep(
            id: 'step_2_3_skewer',
            title: 'O Espeto Fatal',
            shortTheory:
                'O espeto é o inverso da cravada: uma peça mais valiosa (o Rei) é atacada na frente de outra menor. Ao fugir, expõe a peça de trás.',
            demonstrationFen: '4r3/8/8/8/4k3/8/8/R5K1 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_2_3_1',
                title: 'Espetando Rei e Torre',
                instruction: 'Espete o rei inimigo alinhado com a torre na coluna e. Ao fugir do xeque, o rei deixará a torre desprotegida!',
                initialFen: '4r3/8/8/8/4k3/8/8/R5K1 w - - 0 1',
                solutionUciMoves: ['a1e1'],
                hint: 'Coloque a torre em e1 aplicando xeque.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_2_4_discovered',
            title: 'Ataque Descoberto',
            shortTheory:
                'O ataque descoberto ocorre quando o movimento de uma peça abre a linha de visão de outra que estava atrás, criando ameaças duplas.',
            demonstrationFen: 'r1bqk2r/ppp2ppp/2n5/3pP3/3N4/8/PPP2PPP/R1BQK2R w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_2_4_1',
                title: 'Xeque Descoberto com Cavalo',
                instruction: 'Salte com o cavalo capturando material e abrindo o ataque da sua dama.',
                initialFen: 'r1bqk2r/ppp2ppp/2n5/3pP3/3N4/8/PPP2PPP/R1BQK2R w KQkq - 0 1',
                solutionUciMoves: ['d4c6'],
                hint: 'Cxc6 destrói a estrutura e ataca a dama.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 3: PADRÕES DE XEQUE-MATE
      LessonModule(
        id: 'mod_3_checkmate_patterns',
        title: 'Módulo 3: Padrões de Xeque-Mate',
        description: 'Mates temáticos: Fila do Fundo, Anastásia, Boden e Sufocado.',
        iconName: 'psychology',
        steps: [
          LessonStep(
            id: 'step_3_1_back_rank',
            title: 'Mate da Fila do Fundo',
            shortTheory:
                'Quando o Rei adversário faz o roque mas não tem respiro por causa de seus próprios peões, uma Torre na oitava fila aplica mate.',
            demonstrationFen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_3_1_1',
                title: 'Invasão da Oitava Fila',
                instruction: 'Aproveite os peões travados do adversário e aplique o mate de corredor.',
                initialFen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
                solutionUciMoves: ['a1a8'],
                hint: 'Suba sua torre até a8.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_3_2_smothered',
            title: 'Mate Sufocado (Smothered Mate)',
            shortTheory:
                'O mate sufocado é aplicado por um Cavalo quando o Rei adversário está totalmente encurralado e sufocado pelas suas próprias peças.',
            demonstrationFen: '6rk/6pp/8/4N3/8/8/8/7K w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_3_2_1',
                title: 'O Salto Fatal do Cavalo',
                instruction: 'Aplique o xeque-mate sufocado no rei encurralado.',
                initialFen: '6rk/6pp/8/4N3/8/8/8/7K w - - 0 1',
                solutionUciMoves: ['e5f7'],
                hint: 'O cavalo salta de e5 para f7 dando mate indiscutível.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 4: PRINCÍPIOS DE ABERTURA
      LessonModule(
        id: 'mod_4_openings',
        title: 'Módulo 4: Princípios de Abertura',
        description: 'Domínio do centro, desenvolvimento ágil e segurança.',
        iconName: 'menu_book',
        steps: [
          LessonStep(
            id: 'step_4_1_center',
            title: 'A Luta pelo Centro',
            shortTheory:
                'Controlar as casas centrais (e4, d4, e5, d5) permite que suas peças tenham mobilidade máxima para atacar qualquer flanco.',
            demonstrationFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_4_1_1',
                title: 'O Primeiro Lance do Mestre',
                instruction: 'Ocupe o centro com seu peão de rei abrindo alas para o bispo e a dama.',
                initialFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                solutionUciMoves: ['e2e4'],
                hint: 'Avance o peão do rei duas casas (e2 para e4).',
              ),
            ],
          ),
          LessonStep(
            id: 'step_4_2_knights_before_bishops',
            title: 'Desenvolvimento Ágil',
            shortTheory:
                'Desenvolva primeiro os cavalos para controlar o centro e apoiar o roque rápido antes de lançar ataques prematuros.',
            demonstrationFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_4_2_1',
                title: 'Cavalo Pressiona o Centro',
                instruction: 'Desenvolva seu cavalo do rei atacando o peão preto de e5.',
                initialFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1',
                solutionUciMoves: ['g1f3'],
                hint: 'Cf3 desenvolve a peça e ataca e5.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 5: FINAIS PRÁTICOS
      LessonModule(
        id: 'mod_5_endgames',
        title: 'Módulo 5: Finais Práticos',
        description: 'Oposição de reis, regra do quadrado e finais de peões.',
        iconName: 'emoji_events',
        steps: [
          LessonStep(
            id: 'step_5_1_opposition',
            title: 'A Técnica da Oposição',
            shortTheory:
                'A oposição ocorre quando dois reis estão frente a frente separados por apenas uma casa. Quem não tem a vez de jogar domina o espaço.',
            demonstrationFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_5_1_1',
                title: 'Ganhando a Oposição',
                instruction: 'Coloque seu Rei em oposição direta para abrir caminho para o peão passar.',
                initialFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
                solutionUciMoves: ['e3f3'],
                hint: 'Mantenha o Rei ativo na frente do peão.',
              ),
            ],
          ),
          LessonStep(
            id: 'step_5_2_square_rule',
            title: 'A Regra do Quadrado',
            shortTheory:
                'Se o Rei defensor não estiver dentro do quadrado imaginário do peão, o peão coroa sozinho sem precisar de apoio.',
            demonstrationFen: '8/8/4P3/8/8/8/8/k6K w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_5_2_1',
                title: 'Corrida para a Coroação',
                instruction: 'Avance o peão em disparada rumo à oitava fila.',
                initialFen: '8/8/4P3/8/8/8/8/k6K w - - 0 1',
                solutionUciMoves: ['e6e7'],
                hint: 'O rei preto não consegue mais entrar no quadrado.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 6: MAESTRIA POSICIONAL
      LessonModule(
        id: 'mod_6_positional',
        title: 'Módulo 6: Maestria Posicional',
        description: 'Invasão da sétima fila, colunas abertas e postos avançados.',
        iconName: 'architecture',
        steps: [
          LessonStep(
            id: 'step_6_1_seventh_rank',
            title: 'A Invasão da Sétima Fila',
            shortTheory:
                'Uma Torre na sétima fila corta o Rei adversário e ataca a base dos peões inimigos com extrema força.',
            demonstrationFen: '6k1/5ppp/8/8/8/8/8/1R4K1 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_6_1_1',
                title: 'Torre na Sétima',
                instruction: 'Invada a sétima fila atacando os peões de base.',
                initialFen: '6k1/5ppp/8/8/8/8/8/1R4K1 w - - 0 1',
                solutionUciMoves: ['b1b7'],
                hint: 'Tb7 domina a sétima fila.',
              ),
            ],
          ),
        ],
      ),

      // MÓDULO 7: LANCES ESPECIAIS FIDE
      LessonModule(
        id: 'mod_7_special_rules',
        title: 'Módulo 7: Lances Especiais FIDE',
        description: 'Captura En Passant, subpromoções e empates por afogamento.',
        iconName: 'school',
        steps: [
          LessonStep(
            id: 'step_7_1_en_passant',
            title: 'A Captura En Passant',
            shortTheory:
                'Quando um peão inimigo avança duas casas e para ao lado do seu peão, você pode capturá-lo na diagonal como se ele tivesse avançado apenas uma casa.',
            demonstrationFen: 'rnbqkbnr/pp1p1ppp/8/2pPp3/8/8/PPP1PPPP/RNBQKBNR w KQkq e6 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_7_1_1',
                title: 'Capturando En Passant',
                instruction: 'O peão preto avançou duas casas para e5. Capture-o imediatamente En Passant!',
                initialFen: 'rnbqkbnr/pp1p1ppp/8/2pPp3/8/8/PPP1PPPP/RNBQKBNR w KQkq e6 0 1',
                solutionUciMoves: ['d5e6'],
                hint: 'Seu peão de d5 captura o de e5 entrando na casa e6.',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
