import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

// Represents a Kakuro Clue Cell (Diagonal Split)
class KakuroClue {
  final int? rightSum;
  final int? downSum;
  KakuroClue({this.rightSum, this.downSum});
}

// Represents a Kakuro Grid Cell
class KakuroCell {
  bool isBlack;
  KakuroClue? clue;
  int userInput = 0; // 0 means empty
  int expectedAnswer;

  KakuroCell({
    this.isBlack = false, 
    this.clue, 
    this.expectedAnswer = 0
  });
}

class KakuroScreen extends StatefulWidget {
  const KakuroScreen({super.key});

  @override
  State<KakuroScreen> createState() => _KakuroScreenState();
}

class _KakuroScreenState extends State<KakuroScreen> {
  final MindGameService _gameService = MindGameService();

  // A hardcoded 4x4 Kakuro puzzle for demonstration
  // B = Black, C = Clue, W = White input
  late List<List<KakuroCell>> _grid;
  int? _selectedRow;
  int? _selectedCol;
  bool _isComplete = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _loadPuzzle();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _loadPuzzle() {
     // A simple 4x4 Kakuro
     // [ Black ]       [ Clue D:4 ]     [ Clue D:3 ] [ Black ]
     // [ Clue R:3 ]    [ White A:1 ]    [ White A:2 ][ Clue D:2]
     // [ Clue R:4 D:1] [ White A:3 ]    [ White A:1 ][ White A:2]
     // [ Clue R:3 ]    [ White A:.. wait simple: ]
     
     _grid = [
        [
           KakuroCell(isBlack: true),
           KakuroCell(clue: KakuroClue(downSum: 4)),
           KakuroCell(clue: KakuroClue(downSum: 3)),
           KakuroCell(isBlack: true),
        ],
        [
           KakuroCell(clue: KakuroClue(rightSum: 3)),
           KakuroCell(expectedAnswer: 1),
           KakuroCell(expectedAnswer: 2),
           KakuroCell(clue: KakuroClue(downSum: 2)),
        ],
        [
           KakuroCell(clue: KakuroClue(rightSum: 6, downSum: 4)),
           KakuroCell(expectedAnswer: 3),
           KakuroCell(expectedAnswer: 1),
           KakuroCell(expectedAnswer: 2),
        ],
        [
           KakuroCell(clue: KakuroClue(rightSum: 4)),
           KakuroCell(isBlack: true),
           KakuroCell(clue: KakuroClue(rightSum: 1)),
           KakuroCell(expectedAnswer: 1), // Wait downSum 2 -> 2. row 3 rightSum 4 -> N/A it needs to be 3.
           // Let's refine the hardcoded answer for valid sum.
        ]
     ];
     
     // Corrected 4x4 Puzzle
     // R0: [ B ]           [ D=12 ]      [ D=4 ]       [ B ]
     // R1: [ R=11 ]        [ W=8 ]       [ W=3 ]       [ D=6 ]
     // R2: [ R=9, D=.. ]   [ W=4 ]       [ W=1 ]       [ W=4 ]
     // R3: [ R=2 ]         [ B ]         [ B ]         [ W=2 ]
     
     _grid = [
        [
           KakuroCell(isBlack: true),
           KakuroCell(clue: KakuroClue(downSum: 12)),
           KakuroCell(clue: KakuroClue(downSum: 4)),
           KakuroCell(isBlack: true),
        ],
        [
           KakuroCell(clue: KakuroClue(rightSum: 11)),
           KakuroCell(expectedAnswer: 8),
           KakuroCell(expectedAnswer: 3),
           KakuroCell(clue: KakuroClue(downSum: 6)),
        ],
        [
           KakuroCell(clue: KakuroClue(rightSum: 9)),
           KakuroCell(expectedAnswer: 4),
           KakuroCell(expectedAnswer: 1),
           KakuroCell(expectedAnswer: 4), // Wait, down D=6, W=4, W=2 = 6. 
        ],
        [
           KakuroCell(isBlack: true),
           KakuroCell(isBlack: true),
           KakuroCell(clue: KakuroClue(rightSum: 2)),
           KakuroCell(expectedAnswer: 2),
        ]
     ];

     setState(() {
        _selectedRow = null;
        _selectedCol = null;
        _isComplete = false;
     });
  }

  void _onCellTap(int r, int c) {
      if (_grid[r][c].isBlack || _grid[r][c].clue != null || _isComplete) return;
      setState(() {
          _selectedRow = r;
          _selectedCol = c;
      });
  }

  void _onNumberTap(int num) {
      if (_selectedRow == null || _selectedCol == null || _isComplete) return;
      setState(() {
          _grid[_selectedRow!][_selectedCol!].userInput = num;
      });
      _checkWin();
  }
  
  void _onClearTap() {
      if (_selectedRow == null || _selectedCol == null || _isComplete) return;
      setState(() {
          _grid[_selectedRow!][_selectedCol!].userInput = 0;
      });
  }

  void _checkWin() {
      bool isFullAndCorrect = true;
      for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 4; j++) {
              if (!_grid[i][j].isBlack && _grid[i][j].clue == null) {
                  if (_grid[i][j].userInput == 0 || _grid[i][j].userInput != _grid[i][j].expectedAnswer) {
                      isFullAndCorrect = false;
                  }
              }
          }
      }

      if (isFullAndCorrect) {
          setState(() {
             _isComplete = true;
             _score += 100;
          });
          _showWinDialog();
      }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Puzzle Solved!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Excellent mathematical logic!\n\nScore: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
             onPressed: () {
                Navigator.pop(context);
                for(int r = 0; r < 4; r++){
                   for(int c=0; c < 4; c++) _grid[r][c].userInput = 0;
                }
                setState(() => _isComplete = false);
             },
             child: const Text("Reset Puzzle")
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How to Play", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Objective: Fill empty white squares with numbers 1 to 9.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. The sum of numbers in each horizontal block must equal the clue on its left.", style: GoogleFonts.poppins()),
            Text("3. The sum of numbers in each vertical block must equal the clue above it.", style: GoogleFonts.poppins()),
            Text("4. You cannot repeat a number within a single continuous block.", style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Kakuro",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: Column(
        children: [
           Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                   onPressed: _loadPuzzle, 
                   icon: const Icon(Icons.refresh, size: 18), 
                   label: const Text("Restart")
                ),
              ],
            ),
          ),
          
          Expanded(
             child: Center(
                child: AspectRatio(
                   aspectRatio: 1,
                   child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         border: Border.all(color: theme.textTheme.bodyLarge!.color!, width: 2),
                      ),
                      child: GridView.builder(
                         physics: const NeverScrollableScrollPhysics(),
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                         ),
                         itemCount: 16,
                         itemBuilder: (context, index) {
                            int r = index ~/ 4;
                            int c = index % 4;
                            KakuroCell cell = _grid[r][c];
                            bool isSelected = r == _selectedRow && c == _selectedCol;
                            
                            if (cell.isBlack) {
                               return Container(color: Colors.grey.shade900);
                            } else if (cell.clue != null) {
                               return CustomPaint(
                                  painter: KakuroCluePainter(
                                     rightSum: cell.clue!.rightSum,
                                     downSum: cell.clue!.downSum,
                                  ),
                                  child: Container(),
                               );
                            } else {
                               // White Cell
                               return GestureDetector(
                                  onTap: () => _onCellTap(r, c),
                                  child: Container(
                                     color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : theme.cardColor,
                                     child: Center(
                                        child: Text(
                                           cell.userInput == 0 ? "" : cell.userInput.toString(),
                                           style: GoogleFonts.poppins(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                           ),
                                        ),
                                     ),
                                  ),
                               );
                            }
                         },
                      ),
                   )
                ),
             )
          ),
          
          Container(
             padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
             child: Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                   ...List.generate(9, (index) => _buildNumpadButton((index + 1), theme)),
                   _buildClearButton(theme),
                ],
             )
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(int num, ThemeData theme) {
      return GestureDetector(
         onTap: () => _onNumberTap(num),
         child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
               color: theme.cardColor,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: theme.dividerColor),
               boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Center(
               child: Text(num.toString(), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
         ),
      );
  }
  
  Widget _buildClearButton(ThemeData theme) {
      return GestureDetector(
         onTap: _onClearTap,
         child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
               color: Colors.red.shade100,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.red.shade300),
            ),
            child: Center(
               child: Icon(Icons.backspace_outlined, color: Colors.red.shade800),
            ),
         ),
      );
  }
}

// Custom Painter for the diagonally split clue cell
class KakuroCluePainter extends CustomPainter {
  final int? rightSum;
  final int? downSum;

  KakuroCluePainter({this.rightSum, this.downSum});

  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()..color = Colors.grey.shade900;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    Paint linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;
    
    // Draw diagonal
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), linePaint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    if (rightSum != null) {
      textPainter.text = TextSpan(
        text: rightSum.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, 4));
    }

    if (downSum != null) {
      textPainter.text = TextSpan(
        text: downSum.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, size.height - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
