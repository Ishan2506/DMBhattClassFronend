import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class SudokuLiteScreen extends StatefulWidget {
  const SudokuLiteScreen({super.key});

  @override
  State<SudokuLiteScreen> createState() => _SudokuLiteScreenState();
}

class _SudokuLiteScreenState extends State<SudokuLiteScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  bool _gameOver = false;
  
  // 4x4 valid grid
  final List<List<int>> _solution = [
    [1, 2, 3, 4],
    [3, 4, 1, 2],
    [2, 3, 4, 1],
    [4, 1, 2, 3],
  ];

  late List<List<int?>> _board;
  late List<List<bool>> _fixed;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startRound();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _startRound();
  }

  void _startRound() {
    setState(() {
      _gameOver = false;
      // create a puzzle by removing some numbers
      _board = List.generate(4, (i) => List.generate(4, (j) => _solution[i][j]));
      _fixed = List.generate(4, (i) => List.generate(4, (j) => true));
      
      // Remove 8 random numbers
      int removed = 0;
      while (removed < 8) {
        int r = (removed) % 4; // Ensure spread somewhat
        int c = (removed * 3 + 1) % 4;
        if (_board[r][c] != null) {
          _board[r][c] = null;
          _fixed[r][c] = false;
        }
        removed++;
      }
    });
  }

  void _onCellTap(int r, int c) {
    if (_gameOver || _fixed[r][c]) return;

    setState(() {
      if (_board[r][c] == null) {
        _board[r][c] = 1;
      } else {
        _board[r][c] = (_board[r][c]! % 4) + 1;
      }
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    bool win = true;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_board[r][c] != _solution[r][c]) {
          win = false;
          break;
        }
      }
    }

    if (win) {
      setState(() {
        _score += 100;
        _gameOver = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Sudoku Lite (4x4)", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.grid_4x4, "Level: 1", theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
              ],
            ),
            const SizedBox(height: 24),
            if (_gameOver)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text("Puzzle Solved!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                     const SizedBox(height: 16),
                     Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
                     const SizedBox(height: 32),
                     ElevatedButton(
                       onPressed: _startRound,
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                         backgroundColor: theme.colorScheme.primary,
                         foregroundColor: theme.colorScheme.onPrimary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                       ),
                       child: Text("Play Next", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                     )
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Tap empty cells to change value (1-4)", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 32),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(color: theme.dividerColor, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: 16,
                          itemBuilder: (context, index) {
                            int r = index ~/ 4;
                            int c = index % 4;
                            int? val = _board[r][c];
                            bool isFixed = _fixed[r][c];
                            
                            // Highlight 2x2 blocks lightly
                            bool isAltBlock = (r < 2 && c >= 2) || (r >= 2 && c < 2);
                            Color bgColor = isAltBlock ? theme.cardColor.withOpacity(0.5) : theme.cardColor;

                            return GestureDetector(
                              onTap: () => _onCellTap(r, c),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    val == null ? "" : val.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 32, 
                                      fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
                                      color: isFixed ? theme.colorScheme.onSurface : theme.colorScheme.primary
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
