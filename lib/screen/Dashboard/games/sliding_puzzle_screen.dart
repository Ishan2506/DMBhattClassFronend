import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  // 15 Puzzle (4x4)
  List<int> _numbers = [];
  bool _isSolved = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _numbers = List.generate(15, (index) => index + 1);
    _numbers.add(0); // 0 represents empty space
    _shuffle();
    _moves = 0;
    _isSolved = false;
  }

  void _shuffle() {
    // Standard random shuffle isn't always solvable.
    // Instead, manipulate the board with legal moves.
    _numbers.sort(); 
    // Just move the empty tile random times
    /* 
       A robust shuffle: 
       Make 100 random valid moves
    */
    // Quick pseudo shuffle for demo (might produce unsolvable if not careful, but random moves is safe)
    // Actually, simplest is to check inversions for solvability, but moving the empty space is easier.
    
    // We'll sort it (solved state) and then scramble by moving 0.
    _numbers = List.generate(16, (i) => (i + 1) % 16); // 1..15, 0 at end
    
    int emptyIndex = 15;
    final random = List.generate(100, (i) => i);
    
    for (int i = 0; i < 200; i++) {
        List<int> validMoves = [];
        if (emptyIndex % 4 > 0) validMoves.add(emptyIndex - 1); // Left
        if (emptyIndex % 4 < 3) validMoves.add(emptyIndex + 1); // Right
        if (emptyIndex >= 4) validMoves.add(emptyIndex - 4); // Up
        if (emptyIndex < 12) validMoves.add(emptyIndex + 4); // Down
        
        validMoves.shuffle();
        int move = validMoves.first;
        _swap(emptyIndex, move);
        emptyIndex = move;
    }
    
    setState(() {});
  }

  void _onTileTap(int index) {
    if (_numbers[index] == 0) return; // Tapped empty

    int emptyIndex = _numbers.indexOf(0);
    
    // Check adjacency
    bool isAdjacent = false;
    
    // Same row
    if ((index ~/ 4 == emptyIndex ~/ 4) && (index - emptyIndex).abs() == 1) isAdjacent = true;
    // Same col
    if ((index % 4 == emptyIndex % 4) && (index - emptyIndex).abs() == 4) isAdjacent = true;
    
    if (isAdjacent) {
      setState(() {
        _swap(index, emptyIndex);
        _moves++;
        _checkSolved();
      });
    }
  }

  void _swap(int i, int j) {
    int temp = _numbers[i];
    _numbers[i] = _numbers[j];
    _numbers[j] = temp;
  }

  void _checkSolved() {
    bool solved = true;
    for (int i = 0; i < 15; i++) {
      if (_numbers[i] != i + 1) {
        solved = false;
        break;
      }
    }
    if (solved) {
      setState(() {
         _isSolved = true;
      });
      _showWinDialog();
    }
  }
  
  void _showWinDialog() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text("Solved!"),
              content: Text("You solved the puzzle in $_moves moves."),
              actions: [
                  TextButton(onPressed: () {
                      Navigator.pop(context);
                      _startNewGame();
                  }, child: const Text("Play Again"))
              ],
          )
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
             Text("1. The goal is to order tiles 1 to 15.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Tap a tile adjacent to the empty space to move it.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Arrange them row by row: 1-4, 5-8, etc.", style: GoogleFonts.poppins()),
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
        title: "15 Puzzle",
        centerTitle: true,
        actions: [
            IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: _showHowToPlay),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _startNewGame)
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Text("Moves: $_moves", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 32),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(8)
                ),
                child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                        int number = _numbers[index];
                        if (number == 0) return const SizedBox.shrink(); // Empty tile
                        
                        return GestureDetector(
                            onTap: () => _onTileTap(index),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark ? theme.colorScheme.primaryContainer : Colors.brown.shade400,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))
                                    ]
                                ),
                                child: Center(
                                    child: Text(
                                        "$number",
                                        style: GoogleFonts.poppins(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.bold,
                                            color: theme.brightness == Brightness.dark ? theme.colorScheme.onPrimaryContainer : Colors.white
                                        ),
                                    ),
                                ),
                            ),
                        );
                    },
                ),
            ),
            const SizedBox(height: 32),
            if (_isSolved)
             Text("Excellent!", style: GoogleFonts.poppins(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold))

        ],
      ),
    );
  }
}
