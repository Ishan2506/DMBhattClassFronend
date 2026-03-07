import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class SubjectWordSearchScreen extends StatefulWidget {
  const SubjectWordSearchScreen({super.key});

  @override
  State<SubjectWordSearchScreen> createState() => _SubjectWordSearchScreenState();
}

class SearchLevel {
  final String category;
  final List<String> words;

  SearchLevel(this.category, this.words);
}

class _SubjectWordSearchScreenState extends State<SubjectWordSearchScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  
  int _score = 0;
  int _levelIndex = 0;
  
  final int _gridSize = 10;
  late List<List<String>> _grid;
  late List<String> _wordsToFind;
  late Set<String> _foundWords;
  
  // Selection state
  List<Point<int>> _selectedCells = [];
  bool _isDragging = false;

  final List<SearchLevel> _levels = [
    SearchLevel("Geography", ["EARTH", "OCEAN", "MOUNTAIN", "DESERT", "RIVER", "ISLAND"]),
    SearchLevel("Grammar", ["NOUN", "VERB", "ADJECTIVE", "ADVERB", "PRONOUN", "TENSE"]),
    SearchLevel("Math Words", ["ADD", "SUBTRACT", "MULTIPLY", "DIVIDE", "EQUALS", "FRACTION"]),
    SearchLevel("Science (General)", ["ENERGY", "FORCE", "LIGHT", "SOUND", "MATTER", "WATER"]),
    SearchLevel("History", ["KING", "QUEEN", "EMPIRE", "CASTLE", "BATTLE", "ANCIENT"]),
  ];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startLevel();
  }

  void _startLevel() {
    if (_levelIndex >= _levels.length) {
      _showWinDialog();
      return;
    }
    
    _wordsToFind = List.from(_levels[_levelIndex].words);
    _foundWords = {};
    _selectedCells = [];
    _generateGrid();
  }

  void _generateGrid() {
    // 1. Initialize empty grid
    _grid = List.generate(_gridSize, (i) => List.generate(_gridSize, (j) => " "));
    
    // 2. Place words
    for (String word in _wordsToFind) {
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        attempts++;
        int dir = _random.nextInt(4); // 0: horizontal, 1: vertical, 2: diag_down_right, 3: diag_up_right
        
        int rowStart, colStart;
        
        if (dir == 0) { // Horizontal (Left to Right)
            rowStart = _random.nextInt(_gridSize);
            colStart = _random.nextInt(_gridSize - word.length + 1);
        } else if (dir == 1) { // Vertical (Top to Bottom)
            rowStart = _random.nextInt(_gridSize - word.length + 1);
            colStart = _random.nextInt(_gridSize);
        } else if (dir == 2) { // Diagonal Down-Right
            rowStart = _random.nextInt(_gridSize - word.length + 1);
            colStart = _random.nextInt(_gridSize - word.length + 1);
        } else { // Diagonal Up-Right
            rowStart = _random.nextInt(_gridSize - word.length + 1) + word.length - 1;
            colStart = _random.nextInt(_gridSize - word.length + 1);
        }
        
        // Check if path is clear
        bool clear = true;
        for (int i = 0; i < word.length; i++) {
            int r, c;
            if (dir == 0) { r = rowStart; c = colStart + i; }
            else if (dir == 1) { r = rowStart + i; c = colStart; }
            else if (dir == 2) { r = rowStart + i; c = colStart + i; }
            else { r = rowStart - i; c = colStart + i; }
            
            if (_grid[r][c] != " " && _grid[r][c] != word[i]) {
                clear = false;
                break;
            }
        }
        
        if (clear) {
            for (int i = 0; i < word.length; i++) {
                int r, c;
                if (dir == 0) { r = rowStart; c = colStart + i; }
                else if (dir == 1) { r = rowStart + i; c = colStart; }
                else if (dir == 2) { r = rowStart + i; c = colStart + i; }
                else { r = rowStart - i; c = colStart + i; }
                
                _grid[r][c] = word[i];
            }
            placed = true;
        }
      }
    }
    
    // 3. Fill remaining space with random letters
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (int r = 0; r < _gridSize; r++) {
        for (int c = 0; c < _gridSize; c++) {
            if (_grid[r][c] == " ") {
                _grid[r][c] = letters[_random.nextInt(letters.length)];
            }
        }
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }
  
  void _onPanStart(DragStartDetails details, double cellWidth) {
      _isDragging = true;
      _updateSelection(details.localPosition, cellWidth);
  }
  
  void _onPanUpdate(DragUpdateDetails details, double cellWidth) {
      if (_isDragging) {
         _updateSelection(details.localPosition, cellWidth);
      }
  }
  
  void _onPanEnd(DragEndDetails details) {
      _isDragging = false;
      _checkSelection();
  }
  
  void _updateSelection(Offset localPosition, double cellWidth) {
      if (cellWidth <= 0) return;
      
      int col = (localPosition.dx / cellWidth).floor();
      int row = (localPosition.dy / cellWidth).floor();
      
      if (row >= 0 && row < _gridSize && col >= 0 && col < _gridSize) {
          Point<int> p = Point(col, row); // x is col, y is row
          
          if (_selectedCells.isEmpty) {
              setState(() => _selectedCells.add(p));
          } else {
             // In a real word search, we should restrict dragging to a straight line.
             // For simplicity, we just rebuild the line between start and current point.
             Point<int> start = _selectedCells.first;
             
             // Check if it's a straight line (horizontal, vertical, or perfectly diagonal)
             int dx = p.x - start.x;
             int dy = p.y - start.y;
             
             if (dx == 0 || dy == 0 || dx.abs() == dy.abs()) {
                 List<Point<int>> newLine = [];
                 int steps = max(dx.abs(), dy.abs());
                 int stepX = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
                 int stepY = dy == 0 ? 0 : (dy > 0 ? 1 : -1);
                 
                 for (int i = 0; i <= steps; i++) {
                     newLine.add(Point(start.x + i * stepX, start.y + i * stepY));
                 }
                 
                 setState(() => _selectedCells = newLine);
             }
          }
      }
  }

  void _checkSelection() {
     if (_selectedCells.length < 2) {
         setState(() => _selectedCells.clear());
         return;
     }
     
     // Build word forwards and backwards
     String selectedWord = "";
     for (var p in _selectedCells) {
         selectedWord += _grid[p.y][p.x];
     }
     String reversedWord = selectedWord.split('').reversed.join('');
     
     if (_wordsToFind.contains(selectedWord) && !_foundWords.contains(selectedWord)) {
         _foundWords.add(selectedWord);
         _onWordFound();
     } else if (_wordsToFind.contains(reversedWord) && !_foundWords.contains(reversedWord)) {
         _foundWords.add(reversedWord);
         _onWordFound();
     }
     
     setState(() => _selectedCells.clear());
  }
  
  void _onWordFound() {
      _score += 15;
      
      if (_foundWords.length == _wordsToFind.length) {
          // Level complete
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Category Complete!"),
                backgroundColor: Colors.green,
                duration: Duration(milliseconds: 1000),
              ),
          );
          Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                  setState(() {
                      _levelIndex++;
                      _startLevel();
                  });
              }
          });
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Word Found!"),
                backgroundColor: Colors.blue,
                duration: Duration(milliseconds: 500),
              ),
          );
      }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Complete!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You found all the words!\nFinal Score: $_score",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                  _levelIndex = 0;
                  _score = 0;
                  _startLevel();
              });
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit game
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.videogame_asset, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "How to Play",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", "A grid of letters and a list of hidden words will appear."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Words can be hidden horizontally, vertically, or diagonally. They can also be backwards!"),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Touch and drag your finger across the letters to highlight a word."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Find all words in the list to complete the category!"),
              const SizedBox(height: 24),
              // Example Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Example",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLetterCell(theme, "E", true),
                        _buildLetterCell(theme, "A", true),
                        _buildLetterCell(theme, "R", true),
                        _buildLetterCell(theme, "T", true),
                        _buildLetterCell(theme, "H", true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Drag from E to H to find 'EARTH'!",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: Text("Let's Play!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterCell(ThemeData theme, String letter, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_levelIndex >= _levels.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final level = _levels[_levelIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Subject Word Search",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Score Board
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      level.category,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Score: $_score",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Grid
              Expanded(
                flex: 3,
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = min(constraints.maxWidth, constraints.maxHeight);
                      final cellWidth = size / _gridSize;
                      
                      return GestureDetector(
                        onPanStart: (d) => _onPanStart(d, cellWidth),
                        onPanUpdate: (d) => _onPanUpdate(d, cellWidth),
                        onPanEnd: (d) => _onPanEnd(d),
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Stack(
                            children: [
                               // Base grid lines inside
                               ...List.generate(_gridSize * _gridSize, (index) {
                                  int row = index ~/ _gridSize;
                                  int col = index % _gridSize;
                                  
                                  bool isSelected = _selectedCells.contains(Point(col, row));
                                  // Simplified highlighted logic for already found words is complex without tracking their paths.
                                  // For a quick minigame, we rely on the strike-out list below.
                                  
                                  return Positioned(
                                    left: col * cellWidth,
                                    top: row * cellWidth,
                                    width: cellWidth,
                                    height: cellWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _grid[row][col],
                                          style: GoogleFonts.poppins(
                                            fontSize: cellWidth * 0.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                               }),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Words to find list
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                     child: Wrap(
                       spacing: 12,
                       runSpacing: 12,
                       alignment: WrapAlignment.center,
                       children: _wordsToFind.map((word) {
                         bool isFound = _foundWords.contains(word);
                         return Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: isFound ? Colors.green.withOpacity(0.2) : theme.scaffoldBackgroundColor,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: isFound ? Colors.green : theme.dividerColor),
                           ),
                           child: Text(
                             word,
                             style: GoogleFonts.poppins(
                               fontSize: 14,
                               fontWeight: isFound ? FontWeight.bold : FontWeight.w500,
                               color: isFound ? Colors.green.shade700 : theme.textTheme.bodyMedium?.color,
                               decoration: isFound ? TextDecoration.lineThrough : null,
                             ),
                           ),
                         );
                       }).toList(),
                     ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
