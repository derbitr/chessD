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

  /// Catálogo Completo dos 6 Módulos da Trilha de Aprendizado (Estilo Duolingo)
  static List<LessonModule> getCuratedCurriculum() {
    return const [
      LessonModule(
        id: 'mod_1_fundamentals',
        title: 'Módulo 1: Fundamentos',
        description: 'Domínio do tabuleiro, valor das peças e mates essenciais.',
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
                hint: 'A Rainha e o Bispo em c4 cooperam contra o peão de f7.',
              ),
              LessonExercise(
                id: 'ex_1_1_2',
                title: 'Mate da Escadinha',
                instruction: 'Com duas torres, empurre o Rei adversário para a borda do tabuleiro e aplique o mate.',
                initialFen: '4k3/8/8/8/8/8/1R6/2R1K3 w - - 0 1',
                solutionUciMoves: ['b2b8'],
                hint: 'Uma torre corta a fuga e a outra dá o xeque fatal.',
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
                title: 'Roque Menor',
                instruction: 'Garanta a segurança do seu Rei fazendo o roque curto nas alas do rei.',
                initialFen: 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1',
                solutionUciMoves: ['e1g1'],
                hint: 'Mova o rei duas casas em direção à torre de h1.',
              ),
            ],
          ),
        ],
      ),
      LessonModule(
        id: 'mod_2_tactics',
        title: 'Módulo 2: Táticas Essenciais',
        description: 'Garfos, cravadas, espetos e ataques duplos.',
        iconName: 'bolt',
        steps: [
          LessonStep(
            id: 'step_2_1_fork',
            title: 'O Garfo Real do Cavalo',
            shortTheory:
                'Um garfo acontece quando uma única peça ataca simultaneamente dois ou mais alvos inimigos desprotegidos ou de valor superior.',
            demonstrationFen: 'r1bqkb1r/pppp1ppp/2n5/4N3/4n3/8/PPPP1PPP/RNBQKB1R w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_2_1_1',
                title: 'Garfo de Rei e Torre',
                instruction: 'Encontre o salto de cavalo que ataca o Rei e a Torre adversária ao mesmo tempo.',
                initialFen: 'r3k3/ppp2ppp/8/4N3/8/8/PPP2PPP/4K3 w - - 0 1',
                solutionUciMoves: ['e5c6'],
                hint: 'Procure uma casa onde o cavalo ameace dois alvos distantes.',
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
                title: 'Explorando a Peça Cravada',
                instruction: 'O cavalo preto de c6 está cravado no Rei pelo bispo em b5. Aumente a pressão e ganhe material!',
                initialFen: 'r1bqk2r/pppp1ppp/2n5/1B2p3/3PP3/5N2/PPP2PPP/RNBQK2R w KQkq - 0 1',
                solutionUciMoves: ['d4d5'],
                hint: 'Ataque a peça cravada com um peão.',
              ),
            ],
          ),
        ],
      ),
      LessonModule(
        id: 'mod_3_endgames',
        title: 'Módulo 3: Finais Práticos',
        description: 'Oposição, regra do quadrado e técnica de Lucena.',
        iconName: 'trophy',
        steps: [
          LessonStep(
            id: 'step_3_1_opposition',
            title: 'A Técnica da Oposição',
            shortTheory:
                'A oposição ocorre quando dois reis estão frente a frente separados por apenas uma casa. Quem não tem a vez de jogar domina o espaço.',
            demonstrationFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_3_1_1',
                title: 'Ganhando a Oposição',
                instruction: 'Coloque seu Rei em oposição direta para abrir caminho para o peão passar.',
                initialFen: '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
                solutionUciMoves: ['e3f3'],
                hint: 'Mantenha o Rei na frente do seu peão.',
              ),
            ],
          ),
        ],
      ),
      LessonModule(
        id: 'mod_4_openings',
        title: 'Módulo 4: Princípios de Abertura',
        description: 'Domínio do centro, desenvolvimento ágil e profilaxia.',
        iconName: 'book',
        steps: [
          LessonStep(
            id: 'step_4_1_center',
            title: 'A Luta pelo Centro (e4 e d4)',
            shortTheory:
                'Controlar as casas centrais (e4, d4, e5, d5) permite que suas peças tenham mobilidade máxima para atacar qualquer flanco do tabuleiro.',
            demonstrationFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            exercises: [
              LessonExercise(
                id: 'ex_4_1_1',
                title: 'O Primeiro Lance do Mestre',
                instruction: 'Ocupe o centro com seu peão de rei abrindo alas para o Bispo e a Dama.',
                initialFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                solutionUciMoves: ['e2e4'],
                hint: 'Avance o peão do rei duas casas.',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
