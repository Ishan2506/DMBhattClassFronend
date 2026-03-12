import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class PathFinderScreen extends StatefulWidget {
  const PathFinderScreen({super.key});

  @override
  State<PathFinderScreen> createState() => _PathFinderScreenState();
}

class Dot {
  final int x, y;
  final int colorId;
  Dot(this.x, this.y, this.colorId);
}

class PathSegment {
  final int x, y;
  final int colorId;
  PathSegment(this.x, this.y, this.colorId);
}

class _PathFinderScreenState extends State<PathFinderScreen> {
  final MindGameService _gameService = MindGameService();
  
  final int _gridSize = 5;
  List<Dot> _dots = [];
  Map<int, Color> _colorMap = {};
  
  // List of paths, categorized by colorId
  Map<int, List<PathSegment>> _paths = {};
  Map<int, List<PathSegment>> _solutionPaths = {};
  
  int? _activeColorId;
  bool _isGameOver = false;
  int _hintsRemaining = 3;

  final List<Color> _availableColors = [
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
    _paths.clear();
    _solutionPaths.clear();
    _activeColorId = null;
    _isGameOver = false;
    _hintsRemaining = 3;

    final random = Random();
    int levelIndex = random.nextInt(3);

    if (levelIndex == 0) {
        _dots = [
          Dot(0, 0, 0), Dot(4, 0, 0), // Red
          Dot(1, 0, 1), Dot(2, 0, 1), // Blue
          Dot(0, 3, 2), Dot(0, 4, 2), // Green
          Dot(3, 0, 3), Dot(3, 1, 3), // Yellow
        ];
        _solutionPaths = {
          0: [PathSegment(0,0,0), PathSegment(0,1,0), PathSegment(0,2,0), PathSegment(1,2,0), PathSegment(2,2,0), PathSegment(3,2,0), PathSegment(4,2,0), PathSegment(4,1,0), PathSegment(4,0,0)],
          1: [PathSegment(1,0,1), PathSegment(1,1,1), PathSegment(2,1,1), PathSegment(2,0,1)],
          2: [PathSegment(0,3,2), PathSegment(1,3,2), PathSegment(2,3,2), PathSegment(3,3,2), PathSegment(4,3,2), PathSegment(4,4,2), PathSegment(3,4,2), PathSegment(2,4,2), PathSegment(1,4,2), PathSegment(0,4,2)],
          3: [PathSegment(3,0,3), PathSegment(3,1,3)]
        };
    } else if (levelIndex == 1) {
        _dots = [
          Dot(0, 0, 0), Dot(1, 0, 0), // Red
          Dot(2, 0, 1), Dot(4, 4, 1), // Blue
          Dot(0, 2, 2), Dot(1, 3, 2), // Green
          Dot(2, 1, 3), Dot(3, 4, 3), // Yellow
        ];
        _solutionPaths = {
          0: [PathSegment(0,0,0), PathSegment(0,1,0), PathSegment(1,1,0), PathSegment(1,0,0)],
          1: [PathSegment(2,0,1), PathSegment(3,0,1), PathSegment(4,0,1), PathSegment(4,1,1), PathSegment(4,2,1), PathSegment(4,3,1), PathSegment(4,4,1)],
          2: [PathSegment(0,2,2), PathSegment(1,2,2), PathSegment(2,2,2), PathSegment(2,3,2), PathSegment(2,4,2), PathSegment(1,4,2), PathSegment(0,4,2), PathSegment(0,3,2), PathSegment(1,3,2)],
          3: [PathSegment(2,1,3), PathSegment(3,1,3), PathSegment(3,2,3), PathSegment(3,3,3), PathSegment(3,4,3)]
        };
    } else {
        _dots = [
          Dot(0, 0, 0), Dot(4, 4, 0), // Red
          Dot(3, 1, 1), Dot(0, 4, 1), // Blue
          Dot(1, 2, 2), Dot(1, 4, 2), // Green
          Dot(2, 3, 3), Dot(1, 3, 3), // Yellow
        ];
        _solutionPaths = {
          0: [PathSegment(0,0,0), PathSegment(1,0,0), PathSegment(2,0,0), PathSegment(3,0,0), PathSegment(4,0,0), PathSegment(4,1,0), PathSegment(4,2,0), PathSegment(4,3,0), PathSegment(4,4,0)],
          1: [PathSegment(3,1,1), PathSegment(2,1,1), PathSegment(1,1,1), PathSegment(0,1,1), PathSegment(0,2,1), PathSegment(0,3,1), PathSegment(0,4,1)],
          2: [PathSegment(1,2,2), PathSegment(2,2,2), PathSegment(3,2,2), PathSegment(3,3,2), PathSegment(3,4,2), PathSegment(2,4,2), PathSegment(1,4,2)],
          3: [PathSegment(2,3,3), PathSegment(1,3,3)]
        };
    }
    
    _colorMap = {
      0: Colors.red,
      1: Colors.blue,
      2: Colors.green,
      3: Colors.yellow,
    };
    
    for (int id in _colorMap.keys) {
      _paths[id] = [];
    }

    setState(() {});
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_isGameOver) return;
    final pos = _getGridPos(details.localPosition, constraints);
    if (pos == null) return;

    // Check if clicked exactly on a dot
    int? clickedColorId;
    for (var dot in _dots) {
      if (dot.x == pos.dx && dot.y == pos.dy) {
        clickedColorId = dot.colorId;
        break;
      }
    }

    // Check if clicked exactly on end of an existing path
    if (clickedColorId == null) {
      for (var entry in _paths.entries) {
        if (entry.value.isNotEmpty) {
          var lastSeg = entry.value.last;
          if (lastSeg.x == pos.dx && lastSeg.y == pos.dy) {
            clickedColorId = entry.key;
            break;
          }
        }
      }
    }

    if (clickedColorId != null) {
      setState(() {
        _activeColorId = clickedColorId;
        // If restarting from dot, clear existing path
        bool isDot = _dots.any((d) => d.x == pos.dx && d.y == pos.dy && d.colorId == clickedColorId);
        if (isDot) {
           _paths[_activeColorId!] = [PathSegment(pos.dx.toInt(), pos.dy.toInt(), _activeColorId!)];
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_activeColorId == null || _isGameOver) return;
    
    final pos = _getGridPos(details.localPosition, constraints);
    if (pos == null) return;
    
    int x = pos.dx.toInt();
    int y = pos.dy.toInt();
    
    var currentPath = _paths[_activeColorId!]!;
    var lastSeg = currentPath.last;
    
    // Only move horizontally or vertically by 1 unit
    int dx = (x - lastSeg.x).abs();
    int dy = (y - lastSeg.y).abs();
    
    if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
       // Check if square is empty or is our own dot
       bool isOccupiedByOther = false;
       for (var entry in _paths.entries) {
         if (entry.key != _activeColorId) {
           if (entry.value.any((seg) => seg.x == x && seg.y == y)) {
             isOccupiedByOther = true;
           }
         }
       }
       for (var dot in _dots) {
          if (dot.x == x && dot.y == y && dot.colorId != _activeColorId) {
             isOccupiedByOther = true;
          }
       }
       
       // Handle backtracking
       if (currentPath.length >= 2 && currentPath[currentPath.length - 2].x == x && currentPath[currentPath.length - 2].y == y) {
           setState(() {
               currentPath.removeLast();
           });
           return;
       }
       
       if (!isOccupiedByOther) {
           setState(() {
              // If crossing our own path, truncate path
              int idx = currentPath.indexWhere((seg) => seg.x == x && seg.y == y);
              if (idx != -1) {
                  currentPath.removeRange(idx + 1, currentPath.length);
              } else {
                  currentPath.add(PathSegment(x, y, _activeColorId!));
                  
                  // Check if reached target dot
                  bool reachedEnd = _dots.any((d) => d.x == x && d.y == y && d.colorId == _activeColorId && (d.x != currentPath.first.x || d.y != currentPath.first.y));
                  if (reachedEnd) {
                      _activeColorId = null;
                      _checkWinCondition();
                  }
              }
           });
       }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeColorId = null;
    });
  }

  Offset? _getGridPos(Offset localPos, BoxConstraints constraints) {
    double cellSize = constraints.maxWidth / _gridSize;
    int x = (localPos.dx / cellSize).floor();
    int y = (localPos.dy / cellSize).floor();
    if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
      return Offset(x.toDouble(), y.toDouble());
    }
    return null;
  }
  
  void _checkWinCondition() {
      // 1. Check all pairs connected
      for (int id in _colorMap.keys) {
         var path = _paths[id]!;
         if (path.isEmpty) return;
         
         var start = path.first;
         var end = path.last;
         
         var dotsForId = _dots.where((d) => d.colorId == id).toList();
         if (dotsForId.length < 2) continue; // Should always be 2
         
         bool hasD1 = (start.x == dotsForId[0].x && start.y == dotsForId[0].y && end.x == dotsForId[1].x && end.y == dotsForId[1].y) ||
                      (start.x == dotsForId[1].x && start.y == dotsForId[1].y && end.x == dotsForId[0].x && end.y == dotsForId[0].y);
         
         if (!hasD1) return;
      }
      
      // 2. Check grid full
      int totalPathCells = 0;
      for (var path in _paths.values) {
         totalPathCells += path.length;
      }
      
      // If perfect score
      if (totalPathCells == _gridSize * _gridSize) {
         setState(() {
             _isGameOver = true;
         });
         showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Path Complete!"),
              content: const Text("You successfully connected all nodes and filled the board."),
              actions: [
                TextButton(onPressed: () {Navigator.pop(context); _startNewGame();}, child: const Text("Play Again"))
              ],
            )
         );
      }
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Play"),
        content: const Text("Connect matching colored dots with continuous lines.\n\nLines cannot branch off or cross over each other, and you must fill the ENTIRE grid to win.\n\nUse the Lightbulb icon to get a hint which will automatically solve one color's path!"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _isGameOver) return;
    
    // Find a color that isn't correctly solved
    for (int id in _colorMap.keys) {
      bool isCorrect = false;
      var currentPath = _paths[id]!;
      var solPath = _solutionPaths[id]!;
      
      if (currentPath.length == solPath.length) {
          bool forwardMatch = true;
          bool reverseMatch = true;
          for (int i=0; i<solPath.length; i++) {
             if (currentPath[i].x != solPath[i].x || currentPath[i].y != solPath[i].y) forwardMatch = false;
             if (currentPath[i].x != solPath[solPath.length - 1 - i].x || currentPath[i].y != solPath[solPath.length - 1 - i].y) reverseMatch = false;
          }
          isCorrect = forwardMatch || reverseMatch;
      }
      
      if (!isCorrect) {
         setState(() {
            // Set this path to the correct solution
            _paths[id] = List.from(solPath);
            _hintsRemaining--;
            
            // Remove any conflicting segments from other paths
            for (var otherId in _colorMap.keys) {
               if (otherId != id) {
                   var otherPath = _paths[otherId]!;
                   int conflictIdx = -1;
                   for (int i = 0; i < otherPath.length; i++) {
                       bool conflict = solPath.any((seg) => seg.x == otherPath[i].x && seg.y == otherPath[i].y);
                       if (conflict) {
                          conflictIdx = i;
                          break;
                       }
                   }
                   if (conflictIdx != -1) {
                       // Truncate from conflict point
                       otherPath.removeRange(conflictIdx, otherPath.length);
                   }
               }
            }
         });
         _checkWinCondition();
         return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
         title: "Path Finder",
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
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
             double boardSize = constraints.maxWidth < 400 ? constraints.maxWidth - 40 : 360;
             double cellSize = boardSize / _gridSize;
             
             return Container(
               width: boardSize,
               height: boardSize,
               decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: theme.dividerColor, width: 2),
                  borderRadius: BorderRadius.circular(12)
               ),
               child: GestureDetector(
                  onPanStart: (d) => _onPanStart(d, BoxConstraints.tightFor(width: boardSize, height: boardSize)),
                  onPanUpdate: (d) => _onPanUpdate(d, BoxConstraints.tightFor(width: boardSize, height: boardSize)),
                  onPanEnd: _onPanEnd,
                  child: Stack(
                     children: [
                        // Grid lines
                        ...List.generate(_gridSize, (i) => Positioned(
                            left: i * cellSize, top: 0, bottom: 0,
                            child: Container(width: 1, color: theme.dividerColor.withOpacity(0.3))
                        )),
                        ...List.generate(_gridSize, (i) => Positioned(
                            top: i * cellSize, left: 0, right: 0,
                            child: Container(height: 1, color: theme.dividerColor.withOpacity(0.3))
                        )),
                        
                        // Paths
                        CustomPaint(
                           size: Size(boardSize, boardSize),
                           painter: PathPainter(cellSize: cellSize, paths: _paths, colors: _colorMap),
                        ),
                        
                        // Dots
                        ..._dots.map((dot) {
                           return Positioned(
                              left: dot.x * cellSize + (cellSize / 4),
                              top: dot.y * cellSize + (cellSize / 4),
                              child: Container(
                                 width: cellSize / 2,
                                 height: cellSize / 2,
                                 decoration: BoxDecoration(
                                    color: _colorMap[dot.colorId],
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(2,2))]
                                 ),
                              )
                           );
                        }),
                     ],
                  ),
               ),
             );
          }
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final double cellSize;
  final Map<int, List<PathSegment>> paths;
  final Map<int, Color> colors;

  PathPainter({required this.cellSize, required this.paths, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    for (var entry in paths.entries) {
       var segments = entry.value;
       if (segments.length < 2) continue;
       
       Paint paint = Paint()
         ..color = colors[entry.key]!.withOpacity(0.6)
         ..strokeWidth = cellSize / 3
         ..strokeCap = StrokeCap.round
         ..style = PaintingStyle.stroke;

       Path path = Path();
       path.moveTo(segments[0].x * cellSize + cellSize/2, segments[0].y * cellSize + cellSize/2);
       
       for (int i = 1; i < segments.length; i++) {
          path.lineTo(segments[i].x * cellSize + cellSize/2, segments[i].y * cellSize + cellSize/2);
       }
       
       canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
