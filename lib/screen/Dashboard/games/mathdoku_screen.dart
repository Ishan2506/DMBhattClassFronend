import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

// Represents a cage of cells that share a math operation rule
class MathDokuCage {
   final int targetValue;
   final String operatorSymbol; // +, -, *, /
   final List<int> cellIndices; // indices in the 0..15 array

   MathDokuCage(this.targetValue, this.operatorSymbol, this.cellIndices);
}

class MathDokuScreen extends StatefulWidget {
  const MathDokuScreen({super.key});

  @override
  State<MathDokuScreen> createState() => _MathDokuScreenState();
}

class _MathDokuScreenState extends State<MathDokuScreen> {
  final MindGameService _gameService = MindGameService();

  // Hardcoded 4x4 MathDoku for logic demonstration
  late List<int> _grid; // 16 cells
  late List<MathDokuCage> _cages;
  int? _selectedIdx;
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
     _grid = List.filled(16, 0);
     
     // Sample 4x4 MathDoku
     // Cells indices:
     //  0  1  2  3
     //  4  5  6  7
     //  8  9 10 11
     // 12 13 14 15
     
     _cages = [
        MathDokuCage(8, "*", [0, 1]),
        MathDokuCage(3, "-", [2, 3]),
        MathDokuCage(6, "*", [4, 8]),
        MathDokuCage(5, "+", [5, 6]),
        MathDokuCage(2, "/", [7, 11]),
        MathDokuCage(3, "-", [9, 13]),
        MathDokuCage(7, "+", [10, 14, 15]),
        MathDokuCage(4, "", [12]), // Single cell
     ];

     setState(() {
        _selectedIdx = null;
        _isComplete = false;
     });
  }

  void _onCellTap(int idx) {
      if (_isComplete) return;
      setState(() {
          _selectedIdx = idx;
      });
  }

  void _onNumberTap(int num) {
      if (_selectedIdx == null || _isComplete) return;
      if (num < 1 || num > 4) return; // 4x4 grid max num is 4
      
      setState(() {
          _grid[_selectedIdx!] = num;
      });
      _checkWin();
  }
  
  void _onClearTap() {
      if (_selectedIdx == null || _isComplete) return;
      setState(() {
          _grid[_selectedIdx!] = 0;
      });
  }

  void _checkWin() {
      // 1. Check if full
      if (_grid.contains(0)) return;
      
      // 2. Check rows & cols for uniqueness
      for(int i=0; i<4; i++){
          List<int> row = [_grid[i*4], _grid[i*4+1], _grid[i*4+2], _grid[i*4+3]];
          if(row.toSet().length != 4) return;
          
          List<int> col = [_grid[i], _grid[i+4], _grid[i+8], _grid[i+12]];
          if(col.toSet().length != 4) return;
      }
      
      // 3. Check cages
      bool isValid = true;
      for (var cage in _cages) {
         if (!_evaluateCage(cage)) {
             isValid = false;
             break;
         }
      }

      if (isValid) {
          setState(() {
             _isComplete = true;
             _score += 100;
          });
          _showWinDialog();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grid is full but math is incorrect!'), backgroundColor: Colors.orange));
      }
  }
  
  bool _evaluateCage(MathDokuCage cage) {
      List<int> vals = cage.cellIndices.map((i) => _grid[i]).toList();
      if(vals.contains(0)) return false; // Incomplete
      
      if (cage.operatorSymbol == "") return vals[0] == cage.targetValue;
      
      if (cage.operatorSymbol == "+") {
          return vals.fold(0, (a, b) => a + b) == cage.targetValue;
      }
      
      if (cage.operatorSymbol == "*") {
          return vals.fold(1, (a, b) => a * b) == cage.targetValue;
      }
      
      if (cage.operatorSymbol == "-") {
          vals.sort((a,b) => b.compareTo(a));
          return (vals[0] - vals[1]) == cage.targetValue;
      }
      
      if (cage.operatorSymbol == "/") {
          vals.sort((a,b) => b.compareTo(a));
          return (vals[0] / vals[1]) == cage.targetValue;
      }
      
      return false;
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("MathDoku Solved!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Great job evaluating the operators!\n\nScore: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
             onPressed: () {
                Navigator.pop(context);
                for(int i=0; i<16; i++) _grid[i] = 0;
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
            Text("1. Fill the 4x4 grid with digits 1 through 4.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. No digits can repeat in any row or column (like Sudoku).", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Look at the heavily outlined cages. The top-left corner shows a number and an operation (e.g., '8*').", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("4. The numbers in that cage must combine (using that operator) to reach the target number.", style: GoogleFonts.poppins()),
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
        title: "MathDoku",
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
                Text("Grid: 4x4", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
                         border: Border.all(color: theme.textTheme.bodyLarge!.color!, width: 3), // Outer thick border
                      ),
                      child: GridView.builder(
                         physics: const NeverScrollableScrollPhysics(),
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                         ),
                         itemCount: 16,
                         itemBuilder: (context, index) {
                            int r = index ~/ 4;
                            int c = index % 4;
                            int val = _grid[index];
                            bool isSelected = index == _selectedIdx;
                            
                            // Find which cage this cell belongs to calculate borders
                            MathDokuCage? myCage;
                            for(var cage in _cages){
                               if(cage.cellIndices.contains(index)){
                                  myCage = cage; break;
                               }
                            }
                            
                            bool sameCageRight = myCage != null && myCage.cellIndices.contains(index + 1) && c < 3;
                            bool sameCageBottom = myCage != null && myCage.cellIndices.contains(index + 4) && r < 3;
                            bool isTopLeftOfCage = myCage != null && myCage.cellIndices[0] == index;

                            Border border = Border(
                               right: BorderSide(
                                  color: sameCageRight ? theme.dividerColor.withOpacity(0.3) : theme.textTheme.bodyLarge!.color!, 
                                  width: sameCageRight ? 1 : 2
                               ),
                               bottom: BorderSide(
                                  color: sameCageBottom ? theme.dividerColor.withOpacity(0.3) : theme.textTheme.bodyLarge!.color!, 
                                  width: sameCageBottom ? 1 : 2
                               ),
                            );

                            return GestureDetector(
                               onTap: () => _onCellTap(index),
                               child: Container(
                                  decoration: BoxDecoration(
                                     border: border,
                                     color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : theme.cardColor,
                                  ),
                                  child: Stack(
                                     children: [
                                        if (isTopLeftOfCage && myCage != null)
                                           Positioned(
                                              top: 2, left: 4,
                                              child: Text(
                                                 "${myCage.targetValue}${myCage.operatorSymbol}",
                                                 style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                           ),
                                        Center(
                                           child: Text(
                                              val == 0 ? "" : val.toString(),
                                              style: GoogleFonts.poppins(
                                                 fontSize: 28,
                                                 fontWeight: FontWeight.bold,
                                                 color: theme.colorScheme.primary,
                                              ),
                                           ),
                                        ),
                                     ],
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
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                   ...List.generate(4, (index) => _buildNumpadButton((index + 1), theme)),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
               color: theme.cardColor,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: theme.dividerColor),
               boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Center(
               child: Text(num.toString(), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
         ),
      );
  }
  
  Widget _buildClearButton(ThemeData theme) {
      return GestureDetector(
         onTap: _onClearTap,
         child: Container(
            width: 60,
            height: 60,
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
