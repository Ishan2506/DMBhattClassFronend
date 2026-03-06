import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final MindGameService _gameService = MindGameService();

  late List<List<int>> _grid; // 0 means empty
  late List<List<bool>> _isFixed;
  int? _selectedRow;
  int? _selectedCol;
  
  bool _isComplete = false;
  int _score = 0;

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
     _grid = List.generate(9, (_) => List.filled(9, 0));
     _isFixed = List.generate(9, (_) => List.filled(9, false));
     
     // Fill diagonal 3x3 grids first since they are independent
     _fillBox(0, 0);
     _fillBox(3, 3);
     _fillBox(6, 6);
     
     // Fill the rest
     _solveSudoku(0, 0);
     
     // Remove numbers based on difficulty (simplified for immediate generation)
     _removeNumbers(40); // Remove 40 numbers for an easy/medium puzzle
     
     setState(() {
        _selectedRow = null;
        _selectedCol = null;
        _isComplete = false;
     });
  }

  bool _fillBox(int rowStart, int colStart) {
      List<int> nums = [1, 2, 3, 4, 5, 6, 7, 8, 9];
      nums.shuffle();
      int k = 0;
      for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
              _grid[rowStart + i][colStart + j] = nums[k++];
          }
      }
      return true;
  }

  bool _solveSudoku(int row, int col) {
      if (row == 8 && col == 9) return true;
      if (col == 9) { row++; col = 0; }
      if (_grid[row][col] != 0) return _solveSudoku(row, col + 1);

      for (int num = 1; num <= 9; num++) {
          if (_isSafe(row, col, num)) {
              _grid[row][col] = num;
              if (_solveSudoku(row, col + 1)) return true;
              _grid[row][col] = 0;
          }
      }
      return false;
  }

  bool _isSafe(int row, int col, int num) {
      for (int i = 0; i <= 8; i++) if (_grid[row][i] == num) return false;
      for (int i = 0; i <= 8; i++) if (_grid[i][col] == num) return false;
      int startRow = row - row % 3, startCol = col - col % 3;
      for (int i = 0; i < 3; i++)
          for (int j = 0; j < 3; j++)
              if (_grid[i + startRow][j + startCol] == num) return false;
      return true;
  }
  
  void _removeNumbers(int count) {
      var rand = Random();
      int removed = 0;
      while (removed < count) {
          int i = rand.nextInt(9);
          int j = rand.nextInt(9);
          if (_grid[i][j] != 0) {
              _grid[i][j] = 0;
              removed++;
          }
      }
      for(int i = 0; i < 9; i++){
          for(int j = 0; j< 9; j++){
              if(_grid[i][j] != 0) _isFixed[i][j] = true;
          }
      }
  }

  void _onCellTap(int r, int c) {
      if (_isFixed[r][c] || _isComplete) return;
      setState(() {
          _selectedRow = r;
          _selectedCol = c;
      });
  }

  void _onNumberTap(int num) {
      if (_selectedRow == null || _selectedCol == null || _isComplete) return;
      setState(() {
          _grid[_selectedRow!][_selectedCol!] = num;
      });
      _checkWin();
  }
  
  void _onClearTap() {
      if (_selectedRow == null || _selectedCol == null || _isComplete) return;
      setState(() {
          _grid[_selectedRow!][_selectedCol!] = 0;
      });
  }

  void _checkWin() {
      for (int i = 0; i < 9; i++) {
          for (int j = 0; j < 9; j++) {
              if (_grid[i][j] == 0) return; // Not full yet
          }
      }
      
      // Full, now check validity
      bool isValid = true;
      for (int i = 0; i < 9; i++) {
          for (int j = 0; j < 9; j++) {
               int val = _grid[i][j];
               _grid[i][j] = 0; // Temp remove to let _isSafe check remaining
               if (!_isSafe(i, j, val)) {
                   isValid = false;
               }
               _grid[i][j] = val; // Restore
          }
      }

      if (isValid) {
          setState(() {
             _isComplete = true;
             _score += 100;
          });
          _showWinDialog();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Board is full but contains errors!'), backgroundColor: Colors.orange));
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
            Text("1. Objective: Fill the entire 9x9 grid with numbers from 1 to 9.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Constraints:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            Text("   - Each column must contain all numbers from 1 to 9 exactly once.", style: GoogleFonts.poppins()),
            Text("   - Each row must contain all numbers from 1 to 9 exactly once.", style: GoogleFonts.poppins()),
            Text("   - Each 3x3 subgrid must contain all numbers exactly once.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Tap an empty cell, then tap a number below to fill it.", style: GoogleFonts.poppins()),
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
        title: "Sudoku",
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
                   onPressed: _generatePuzzle, 
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
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                         border: Border.all(color: theme.textTheme.bodyLarge!.color!, width: 3),
                      ),
                      child: GridView.builder(
                         physics: const NeverScrollableScrollPhysics(),
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                         ),
                         itemCount: 81,
                         itemBuilder: (context, index) {
                            int r = index ~/ 9;
                            int c = index % 9;
                            int val = _grid[r][c];
                            bool isFixed = _isFixed[r][c];
                            bool isSelected = r == _selectedRow && c == _selectedCol;
                            
                            // Determine borders for 3x3 blocks
                            Border border = Border(
                               right: BorderSide(color: c % 3 == 2 ? theme.textTheme.bodyLarge!.color! : theme.dividerColor, width: c % 3 == 2 ? 2 : 1),
                               bottom: BorderSide(color: r % 3 == 2 ? theme.textTheme.bodyLarge!.color! : theme.dividerColor, width: r % 3 == 2 ? 2 : 1),
                            );

                            return GestureDetector(
                               onTap: () => _onCellTap(r, c),
                               child: Container(
                                  decoration: BoxDecoration(
                                     border: border,
                                     color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) 
                                           : (isFixed ? theme.cardColor : theme.scaffoldBackgroundColor),
                                  ),
                                  child: Center(
                                     child: Text(
                                        val == 0 ? "" : val.toString(),
                                        style: GoogleFonts.poppins(
                                           fontSize: 20,
                                           fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
                                           color: isFixed ? theme.textTheme.bodyLarge?.color : theme.colorScheme.primary,
                                        ),
                                     ),
                                  ),
                               ),
                            );
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
               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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
