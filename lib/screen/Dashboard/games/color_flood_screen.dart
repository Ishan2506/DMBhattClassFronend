import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class ColorFloodScreen extends StatefulWidget {
  const ColorFloodScreen({super.key});

  @override
  State<ColorFloodScreen> createState() => _ColorFloodScreenState();
}

class _ColorFloodScreenState extends State<ColorFloodScreen> {
  final MindGameService _gameService = MindGameService();
  
  final int _gridSize = 12;
  final int _maxMoves = 25;
  
  List<List<int>> _grid = [];
  int _moves = 0;
  bool _isGameOver = false;
  bool _won = false;
  int _hintsRemaining = 3;

  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
    _gameService.startSession(context);
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startNewGame() {
    final random = Random();
    _grid = List.generate(_gridSize, (i) => List.generate(_gridSize, (j) => random.nextInt(_colors.length)));
    _moves = 0;
    _isGameOver = false;
    _won = false;
    _hintsRemaining = 3;
    setState(() {});
  }

  void _flood(int newColor) {
    if (_isGameOver) return;
    int oldColor = _grid[0][0];
    if (oldColor == newColor) return;

    // DFS or BFS to flood fill
    List<Point<int>> queue = [const Point(0, 0)];
    List<List<bool>> visited = List.generate(_gridSize, (i) => List.generate(_gridSize, (j) => false));
    visited[0][0] = true;

    while (queue.isNotEmpty) {
      var p = queue.removeLast();
      _grid[p.x][p.y] = newColor;

      var neighbors = [
        Point(p.x - 1, p.y), Point(p.x + 1, p.y),
        Point(p.x, p.y - 1), Point(p.x, p.y + 1)
      ];

      for (var n in neighbors) {
        if (n.x >= 0 && n.x < _gridSize && n.y >= 0 && n.y < _gridSize) {
          if (!visited[n.x][n.y] && _grid[n.x][n.y] == oldColor) {
            visited[n.x][n.y] = true;
            queue.add(n);
          }
        }
      }
    }

    setState(() {
      _moves++;
      _checkWinCondition();
    });
  }

  void _checkWinCondition() {
    int targetColor = _grid[0][0];
    bool allSame = true;
    for (int i = 0; i < _gridSize; i++) {
        for (int j = 0; j < _gridSize; j++) {
            if (_grid[i][j] != targetColor) {
                allSame = false;
                break;
            }
        }
    }

    if (allSame) {
      _isGameOver = true;
      _won = true;
      _showWinDialog();
    } else if (_moves >= _maxMoves) {
       _isGameOver = true;
       _showLoseDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Board Flooded!"),
        content: Text("You flooded the board in $_moves moves."),
        actions: [
          TextButton(onPressed: () {Navigator.pop(context); _startNewGame();}, child: const Text("Play Again"))
        ],
      )
    );
  }

  void _showLoseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Out of Moves!"),
        content: const Text("You couldn't flood the board in time."),
        actions: [
          TextButton(onPressed: () {Navigator.pop(context); _startNewGame();}, child: const Text("Try Again"))
        ],
      )
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Play"),
        content: const Text("Your goal is to flood the entire board with a single color.\n\nStart from the top-left corner. Tap a color at the bottom to change your flooded area to that color, absorbing adjacent squares of the same color.\n\nDo this in the minimum number of moves!\n\nUse the Lightbulb icon to get a hint for the best next color."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _isGameOver) return;

    int bestColor = -1;
    int maxAbsorbed = -1;

    int currentColor = _grid[0][0];

    // Find current flooded component
    List<Point<int>> currentFlood = [];
    List<Point<int>> queue = [const Point(0, 0)];
    List<List<bool>> visited = List.generate(_gridSize, (i) => List.generate(_gridSize, (j) => false));
    visited[0][0] = true;

    while (queue.isNotEmpty) {
      var p = queue.removeLast();
      currentFlood.add(p);

      var neighbors = [
        Point(p.x - 1, p.y), Point(p.x + 1, p.y),
        Point(p.x, p.y - 1), Point(p.x, p.y + 1)
      ];

      for (var n in neighbors) {
        if (n.x >= 0 && n.x < _gridSize && n.y >= 0 && n.y < _gridSize) {
          if (!visited[n.x][n.y] && _grid[n.x][n.y] == currentColor) {
            visited[n.x][n.y] = true;
            queue.add(n);
          }
        }
      }
    }

    // For each possible color, see how many adjacent unflooded squares it touches
    for (int c = 0; c < _colors.length; c++) {
      if (c == currentColor) continue;

      int absorbedNodes = 0;
      List<List<bool>> counted = List.generate(_gridSize, (i) => List.generate(_gridSize, (j) => false));

      for (var p in currentFlood) {
        var neighbors = [
          Point(p.x - 1, p.y), Point(p.x + 1, p.y),
          Point(p.x, p.y - 1), Point(p.x, p.y + 1)
        ];

        for (var n in neighbors) {
          if (n.x >= 0 && n.x < _gridSize && n.y >= 0 && n.y < _gridSize) {
             if (!counted[n.x][n.y] && _grid[n.x][n.y] == c) {
                 // Try DFS from this new node to see how big the component of color 'c' is
                 int componentSize = 0;
                 List<Point<int>> cQueue = [n];
                 counted[n.x][n.y] = true;

                 while (cQueue.isNotEmpty) {
                    var cp = cQueue.removeLast();
                    componentSize++;

                    var cNeighbors = [
                      Point(cp.x - 1, cp.y), Point(cp.x + 1, cp.y),
                      Point(cp.x, cp.y - 1), Point(cp.x, cp.y + 1)
                    ];
                    
                    for (var cn in cNeighbors) {
                        if (cn.x >= 0 && cn.x < _gridSize && cn.y >= 0 && cn.y < _gridSize) {
                            if (!counted[cn.x][cn.y] && _grid[cn.x][cn.y] == c) {
                                counted[cn.x][cn.y] = true;
                                cQueue.add(cn);
                            }
                        }
                    }
                 }
                 absorbedNodes += componentSize;
             }
          }
        }
      }

      if (absorbedNodes > maxAbsorbed) {
         maxAbsorbed = absorbedNodes;
         bestColor = c;
      }
    }
    
    if (bestColor != -1) {
       setState(() {
          _hintsRemaining--;
       });
       
       final colorNames = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"];
       final colorName = colorNames[bestColor];
       
       showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hint"),
            content: Text("Try choosing $colorName next. It will absorb $maxAbsorbed squares!"),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: "Color Flood",
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: _showHowToPlay),
          IconButton(
            icon: Badge(
              label: Text("$_hintsRemaining"),
              isLabelVisible: _hintsRemaining > 0,
              child: const Icon(Icons.lightbulb, color: Colors.amber),
            ),
            onPressed: !_isGameOver && _hintsRemaining > 0 ? _useHint : null,
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _startNewGame),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                   Text("Moves: $_moves / $_maxMoves", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
               ]
            ),
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                   border: Border.all(color: theme.dividerColor, width: 2),
                   borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  children: List.generate(_gridSize, (i) => Expanded(
                     child: Row(
                        children: List.generate(_gridSize, (j) => Expanded(
                           child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              color: _colors[_grid[i][j]]
                           )
                        ))
                     )
                  ))
                ),
              ),
            ),
          ),
          // Color Selectors
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
               spacing: 16, runSpacing: 16,
               alignment: WrapAlignment.center,
               children: List.generate(_colors.length, (index) {
                  return GestureDetector(
                     onTap: () => _flood(index),
                     child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                           color: _colors[index],
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.white, width: 2),
                           boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
                        ),
                     ),
                  );
               }),
            ),
          )
        ],
      )
    );
  }
}
