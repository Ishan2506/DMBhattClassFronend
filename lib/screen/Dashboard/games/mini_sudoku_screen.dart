import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class MiniSudokuScreen extends StatefulWidget {
  const MiniSudokuScreen({super.key});

  @override
  State<MiniSudokuScreen> createState() => _MiniSudokuScreenState();
}

class _MiniSudokuScreenState extends State<MiniSudokuScreen> {
  final MindGameService _gameService = MindGameService();
  
  // 4x4 Sudoku
  late List<List<int>> _grid;
  late List<List<bool>> _isGiven;
  int? _selectedRow;
  int? _selectedCol;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _generatePuzzle();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _generatePuzzle() {
    // Start with a solved 4x4
    _grid = [
      [1, 2, 3, 4],
      [3, 4, 1, 2],
      [2, 3, 4, 1],
      [4, 1, 2, 3],
    ];
    
    // Shuffle rows and cols within bands
    _grid.shuffle(); // Shuffle bands? It's just 2 bands
    
    // Transpose
    if (Random().nextBool()) {
      _grid = List.generate(4, (i) => List.generate(4, (j) => _grid[j][i]));
    }

    // Remap numbers
    List<int> mapping = [1, 2, 3, 4]..shuffle();
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            _grid[i][j] = mapping[_grid[i][j] - 1];
        }
    }

    _isGiven = List.generate(4, (_) => List.generate(4, (_) => true));
    
    // Remove some numbers (6-8 for easy-medium 4x4)
    int toRemove = 8;
    int removed = 0;
    while (removed < toRemove) {
        int r = Random().nextInt(4);
        int c = Random().nextInt(4);
        if (_isGiven[r][c]) {
            _isGiven[r][c] = false;
            _grid[r][c] = 0;
            removed++;
        }
    }

    setState(() {});
  }

  void _onCellTap(int r, int c) {
    if (_isGiven[r][c]) {
        setState(() {
            _selectedRow = null;
            _selectedCol = null;
        });
        return;
    }
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
  }

  void _inputNumber(int n) {
    if (_selectedRow == null) return;
    
    setState(() {
      _grid[_selectedRow!][_selectedCol!] = n;
      _checkWin();
    });
  }

  void _checkWin() {
    // Check if full
    for (var row in _grid) {
      if (row.contains(0)) return;
    }

    // Validation
    bool isValid = true;
    for (int i = 0; i < 4; i++) {
        Set<int> rowSet = {};
        Set<int> colSet = {};
        for (int j = 0; j < 4; j++) {
            rowSet.add(_grid[i][j]);
            colSet.add(_grid[j][i]);
        }
        if (rowSet.length != 4 || colSet.length != 4) isValid = false;
    }

    // Blocks (2x2)
    for (int r = 0; r < 4; r += 2) {
        for (int c = 0; c < 4; c += 2) {
            Set<int> blockSet = {
                _grid[r][c], _grid[r+1][c],
                _grid[r][c+1], _grid[r+1][c+1]
            };
            if (blockSet.length != 4) isValid = false;
        }
    }

    if (isValid) {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Logic Master!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("You solved the Mini Sudoku successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generatePuzzle();
            },
            child: const Text("New Game"),
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
            Text("1. Fill the 4x4 grid so that every row, every column, and every 2x2 box contains numbers 1 to 4.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Tap an empty cell to select it.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Tap a number from the keypad to place it.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("4. No number can repeat in the same row, column, or box!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
        title: "Logic Grid",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8)
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  int r = index ~/ 4;
                  int c = index % 4;
                  bool isSelected = _selectedRow == r && _selectedCol == c;
                  bool isGiven = _isGiven[r][c];
                  int val = _grid[r][c];

                  return GestureDetector(
                    onTap: () => _onCellTap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary.withOpacity(0.2) 
                            : (isGiven ? theme.dividerColor.withOpacity(0.05) : Colors.transparent),
                        border: Border(
                          top: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 0.5),
                          left: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 0.5),
                          bottom: BorderSide(
                            color: r == 1 ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.2), 
                            width: r == 1 ? 2 : 0.5
                          ),
                          right: BorderSide(
                            color: c == 1 ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.2), 
                            width: c == 1 ? 2 : 0.5
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          val == 0 ? "" : "$val",
                          style: GoogleFonts.poppins(
                            fontSize: 24, 
                            fontWeight: isGiven ? FontWeight.bold : FontWeight.normal,
                            color: isGiven ? theme.colorScheme.onSurface : theme.colorScheme.primary
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Keypad
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 2, 3, 4].map((n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _inputNumber(n),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("$n", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _generatePuzzle, 
            icon: const Icon(Icons.refresh), 
            label: const Text("Reset Puzzle")
          )
        ],
      ),
    );
  }
}
