import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  // 4x4 Grid
  List<List<int>> grid = [];
  List<List<int>> previousGrid = [];
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isWon = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startNewGame();
  }

  void _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('2048_high_score') ?? 0;
    });
  }

  void _saveHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('2048_high_score', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _startNewGame() {
    setState(() {
      grid = List.generate(4, (_) => List.generate(4, (_) => 0));
      score = 0;
      isGameOver = false;
      isWon = false;
      _spawnNewTile();
      _spawnNewTile();
    });
  }

  void _spawnNewTile() {
    List<Point<int>> emptySpots = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) {
          emptySpots.add(Point(i, j));
        }
      }
    }

    if (emptySpots.isNotEmpty) {
      final random = Random();
      final point = emptySpots[random.nextInt(emptySpots.length)];
      // 90% chance of 2, 10% chance of 4
      grid[point.x][point.y] = random.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  // --- Move Logic ---

  void _onSwipeLeft() {
    setState(() {
      bool moved = false;
      for (int i = 0; i < 4; i++) {
        if (_mergeRowLeft(grid[i])) moved = true;
      }
      _afterMove(moved);
    });
  }

  void _onSwipeRight() {
    setState(() {
      bool moved = false;
      for (int i = 0; i < 4; i++) {
        // Reverse row, merge left, reverse back
        List<int> reversed = grid[i].reversed.toList();
        if (_mergeRowLeft(reversed)) {
          grid[i] = reversed.reversed.toList();
          moved = true;
        }
      }
      _afterMove(moved);
    });
  }

  void _onSwipeUp() {
    setState(() {
      bool moved = false;
      for (int col = 0; col < 4; col++) {
        List<int> column = [grid[0][col], grid[1][col], grid[2][col], grid[3][col]];
        if (_mergeRowLeft(column)) {
          for (int row = 0; row < 4; row++) {
            grid[row][col] = column[row];
          }
          moved = true;
        }
      }
      _afterMove(moved);
    });
  }

  void _onSwipeDown() {
    setState(() {
      bool moved = false;
      for (int col = 0; col < 4; col++) {
        List<int> column = [grid[0][col], grid[1][col], grid[2][col], grid[3][col]];
        List<int> reversed = column.reversed.toList();
        if (_mergeRowLeft(reversed)) {
          column = reversed.reversed.toList();
          for (int row = 0; row < 4; row++) {
            grid[row][col] = column[row];
          }
          moved = true;
        }
      }
      _afterMove(moved);
    });
  }

  bool _mergeRowLeft(List<int> row) {
    bool moved = false;
    
    // 1. Remove Zeros (Shift Left)
    List<int> newRow = row.where((e) => e != 0).toList();
    
    // 2. Merge
    for (int i = 0; i < newRow.length - 1; i++) {
      if (newRow[i] == newRow[i + 1]) {
        newRow[i] *= 2;
        score += newRow[i];
        newRow[i + 1] = 0; // Mark for removal
        moved = true;
        if (newRow[i] == 2048 && !isWon) isWon = true; 
      }
    }
    
    // 3. Remove Zeros again (after merge)
    newRow = newRow.where((e) => e != 0).toList();
    
    // 4. Pad with zeros
    while (newRow.length < 4) {
      newRow.add(0);
    }
    
    // Check if row changed
    for (int i = 0; i < 4; i++) {
      if (row[i] != newRow[i]) {
        row[i] = newRow[i];
        moved = true;
      }
    }
    
    return moved;
  }

  void _afterMove(bool moved) {
    if (moved) {
      _spawnNewTile();
      _saveHighScore();
      if (_checkGameOver()) {
        isGameOver = true;
      }
    }
  }

  bool _checkGameOver() {
    // Check for zeros
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return false;
      }
    }
    
    // Check for merges
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (j < 3 && grid[i][j] == grid[i][j+1]) return false; // Check right
        if (i < 3 && grid[i][j] == grid[i+1][j]) return false; // Check down
      }
    }
    
    return true;
  }
  
  Color _getTileColor(int value) {
    switch (value) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFFCDC1B4);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "2048 Puzzle",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _startNewGame,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scores
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildScoreBoard("SCORE", score),
                 _buildScoreBoard("BEST", highScore),
               ],
             ),
           ),
           
           const SizedBox(height: 16),
           
           // Grid
           GestureDetector(
             onHorizontalDragEnd: (details) {
               if (details.primaryVelocity! < 0) _onSwipeLeft();
               else if (details.primaryVelocity! > 0) _onSwipeRight();
             },
             onVerticalDragEnd: (details) {
               if (details.primaryVelocity! < 0) _onSwipeUp();
               else if (details.primaryVelocity! > 0) _onSwipeDown();
             },
             child: Container(
               width: MediaQuery.of(context).size.width * 0.9,
               height: MediaQuery.of(context).size.width * 0.9,
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: theme.colorScheme.primary.withOpacity(0.5),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: GridView.builder(
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 4,
                   crossAxisSpacing: 8,
                   mainAxisSpacing: 8,
                 ),
                 itemCount: 16,
                 itemBuilder: (context, index) {
                   int row = index ~/ 4;
                   int col = index % 4;
                   int value = grid[row][col];
                   
                   return AnimatedContainer(
                     duration: const Duration(milliseconds: 200),
                     decoration: BoxDecoration(
                       color: _getTileColor(value),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Center(
                       child: value == 0 
                         ? null 
                         : Text(
                             "$value",
                             style: GoogleFonts.poppins(
                               fontSize: value > 512 ? 24 : 32,
                               fontWeight: FontWeight.bold,
                               color: _getTextColor(value),
                             ),
                           ),
                     ),
                   );
                 },
               ),
             ),
           ),
           
           const SizedBox(height: 32),
           
           if (isGameOver)
             Column(
               children: [
                 Text("Game Over!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF776E65))),
                 const SizedBox(height: 8),
                 ElevatedButton(
                   onPressed: _startNewGame, 
                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8F7A66)),
                   child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                 )
               ],
             ),
             
          if (isWon)
             Column(
               children: [
                 Text("You Won!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
               ],
             ),
             
           const SizedBox(height: 24),
           Text(
             "Join the numbers and get to the 2048 tile!",
             style: GoogleFonts.poppins(color: const Color(0xFF776E65)),
           ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(String label, int score) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.grey[800] : theme.colorScheme.primary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFFEEE4DA))),
          Text("$score", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
