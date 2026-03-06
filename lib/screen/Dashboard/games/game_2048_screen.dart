import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

enum SwipeDirection { up, down, left, right }

class _Game2048ScreenState extends State<Game2048Screen> {
  final MindGameService _gameService = MindGameService();

  late List<List<int>> _grid;
  int _score = 0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _initGame();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _initGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _isGameOver = false;
    _addRandomTile();
    _addRandomTile();
    setState(() {});
  }

  void _addRandomTile() {
    List<Point<int>> available = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) available.add(Point(r, c));
      }
    }
    if (available.isEmpty) return;
    
    var rand = Random();
    Point<int> cell = available[rand.nextInt(available.length)];
    // 90% chance for 2, 10% chance for 4
    _grid[cell.x][cell.y] = rand.nextDouble() < 0.9 ? 2 : 4;
  }

  void _handleSwipe(SwipeDirection direction) {
    if (_isGameOver) return;
    
    bool changed = false;
    
    switch (direction) {
       case SwipeDirection.left: changed = _moveLeft(); break;
       case SwipeDirection.right: changed = _moveRight(); break;
       case SwipeDirection.up: changed = _moveUp(); break;
       case SwipeDirection.down: changed = _moveDown(); break;
    }

    if (changed) {
      _addRandomTile();
      _checkGameOver();
      setState(() {});
    }
  }

  bool _moveLeft() {
    bool changed = false;
    for (int r = 0; r < 4; r++) {
       List<int> row = _grid[r].where((val) => val != 0).toList();
       for(int i = 0; i < row.length - 1; i++){
          if(row[i] == row[i+1]){
             row[i] *= 2;
             _score += row[i];
             row.removeAt(i+1);
          }
       }
       while(row.length < 4) row.add(0);
       for(int c=0; c<4; c++){
          if(_grid[r][c] != row[c]){
             _grid[r][c] = row[c];
             changed = true;
          }
       }
    }
    return changed;
  }

  bool _moveRight() {
    bool changed = false;
    for (int r = 0; r < 4; r++) {
       List<int> row = _grid[r].where((val) => val != 0).toList();
       for(int i = row.length - 1; i > 0; i--){
          if(row[i] == row[i-1]){
             row[i] *= 2;
             _score += row[i];
             row.removeAt(i-1);
             i--; // Skip the merged item
          }
       }
       while(row.length < 4) row.insert(0, 0);
       for(int c=0; c<4; c++){
          if(_grid[r][c] != row[c]){
             _grid[r][c] = row[c];
             changed = true;
          }
       }
    }
    return changed;
  }

  bool _moveUp() {
    bool changed = false;
    for (int c = 0; c < 4; c++) {
       List<int> col = [];
       for(int r=0; r<4; r++) if(_grid[r][c] != 0) col.add(_grid[r][c]);
       
       for(int i = 0; i < col.length - 1; i++){
          if(col[i] == col[i+1]){
             col[i] *= 2;
             _score += col[i];
             col.removeAt(i+1);
          }
       }
       while(col.length < 4) col.add(0);
       for(int r=0; r<4; r++){
          if(_grid[r][c] != col[r]){
             _grid[r][c] = col[r];
             changed = true;
          }
       }
    }
    return changed;
  }

  bool _moveDown() {
    bool changed = false;
     for (int c = 0; c < 4; c++) {
       List<int> col = [];
       for(int r=0; r<4; r++) if(_grid[r][c] != 0) col.add(_grid[r][c]);
       
       for(int i = col.length - 1; i > 0; i--){
          if(col[i] == col[i-1]){
             col[i] *= 2;
             _score += col[i];
             col.removeAt(i-1);
             i--;
          }
       }
       while(col.length < 4) col.insert(0, 0);
       for(int r=0; r<4; r++){
          if(_grid[r][c] != col[r]){
             _grid[r][c] = col[r];
             changed = true;
          }
       }
    }
    return changed;
  }

  void _checkGameOver() {
      // Check for empty spaces
      for(int r=0; r<4; r++){
         for(int c=0; c<4; c++){
             if(_grid[r][c] == 0) return;
         }
      }
      
      // Check for horizontal merges remaining
      for(int r=0; r<4; r++){
         for(int c=0; c<3; c++){
             if(_grid[r][c] == _grid[r][c+1]) return;
         }
      }

      // Check for vertical merges remaining
      for(int c=0; c<4; c++){
         for(int r=0; r<3; r++){
             if(_grid[r][c] == _grid[r+1][c]) return;
         }
      }
      
      _isGameOver = true;
      _showResultDialog();
  }
  
  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "No more moves left.\n\nFinal Score: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text("Play Again"),
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
            Text("1. Objective: Slide identical tiles together to merge them and reach the 2048 tile.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Swipe Up, Down, Left, or Right to cleanly slide all tiles on the board.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Every time two tiles with the same number touch during a slide, they merge into one with double the value (2+2=4, 4+4=8, etc).", style: GoogleFonts.poppins()),
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
        title: "2048",
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
                Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                   onPressed: _initGame, 
                   icon: const Icon(Icons.refresh), 
                   label: const Text("Restart")
                ),
              ],
            ),
          ),
          
          Expanded(
             child: Center(
                child: GestureDetector(
                   onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) _handleSwipe(SwipeDirection.up);
                      else if (details.primaryVelocity! > 0) _handleSwipe(SwipeDirection.down);
                   },
                   onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) _handleSwipe(SwipeDirection.left);
                      else if (details.primaryVelocity! > 0) _handleSwipe(SwipeDirection.right);
                   },
                   child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                         color: Colors.brown.shade300,
                         borderRadius: BorderRadius.circular(16),
                      ),
                      child: AspectRatio(
                         aspectRatio: 1,
                         child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 4,
                               crossAxisSpacing: 8,
                               mainAxisSpacing: 8,
                            ),
                            itemCount: 16,
                            itemBuilder: (context, index) {
                               int r = index ~/ 4;
                               int c = index % 4;
                               int val = _grid[r][c];
                               
                               return Container(
                                  decoration: BoxDecoration(
                                     color: _getTileColor(val),
                                     borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                     child: Text(
                                        val == 0 ? "" : val.toString(),
                                        style: GoogleFonts.poppins(
                                           fontSize: val > 512 ? 24 : 32,
                                           fontWeight: FontWeight.bold,
                                           color: val <= 4 ? Colors.grey.shade800 : Colors.white,
                                        ),
                                     ),
                                  ),
                               );
                            },
                         ),
                      ),
                   )
                ),
             )
          ),
          Padding(
             padding: const EdgeInsets.only(bottom: 32.0),
             child: Text("Swipe to match tiles!", style: GoogleFonts.poppins(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  Color _getTileColor(int value) {
     switch (value) {
        case 2: return Colors.orange.shade50;
        case 4: return Colors.orange.shade100;
        case 8: return Colors.orange.shade300;
        case 16: return Colors.orange.shade500;
        case 32: return Colors.red.shade400;
        case 64: return Colors.red.shade600;
        case 128: return Colors.yellow.shade600;
        case 256: return Colors.yellow.shade700;
        case 512: return Colors.yellow.shade800;
        case 1024: return Colors.green.shade600;
        case 2048: return Colors.green.shade800;
        default: return Colors.brown.shade200; // 0 or empty background
     }
  }
}
