import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class MagicSquareScreen extends StatefulWidget {
  const MagicSquareScreen({super.key});

  @override
  State<MagicSquareScreen> createState() => _MagicSquareScreenState();
}

class _MagicSquareScreenState extends State<MagicSquareScreen> {
  final MindGameService _gameService = MindGameService();

  late List<int> _grid; // 9 cells for a 3x3
  late List<bool> _isFixed;
  int? _selectedIdx;
  
  bool _isComplete = false;
  int _score = 0;
  final int _magicConstant = 15; // 3x3 normal magic square constant

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
     _grid = List.filled(9, 0);
     _isFixed = List.filled(9, false);
     
     // A valid 3x3 magic square
     // 8 1 6
     // 3 5 7
     // 4 9 2
     List<int> validSquare = [8, 1, 6, 3, 5, 7, 4, 9, 2];
     
     // We will reveal 3 numbers to make it solvable but challenging
     _grid[0] = validSquare[0]; _isFixed[0] = true;
     _grid[4] = validSquare[4]; _isFixed[4] = true; // Center is always 5 for 1-9
     _grid[5] = validSquare[5]; _isFixed[5] = true;

     setState(() {
        _selectedIdx = null;
        _isComplete = false;
     });
  }

  void _onCellTap(int idx) {
      if (_isFixed[idx] || _isComplete) return;
      setState(() {
          _selectedIdx = idx;
      });
  }

  void _onNumberTap(int num) {
      if (_selectedIdx == null || _isComplete) return;
      
      // Prevent entering a number already on the board in Magic Square 1-9
      if (_grid.contains(num)) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Number $num is already on the board!'), backgroundColor: Colors.orange, duration: const Duration(milliseconds: 500)));
         return;
      }
      
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
      if (_grid.contains(0)) return; // Not full
      
      bool isValid = true;
      
      // Rows
      for(int r=0; r<3; r++) {
         if(_grid[r*3] + _grid[r*3+1] + _grid[r*3+2] != _magicConstant) isValid = false;
      }
      // Cols
      for(int c=0; c<3; c++) {
         if(_grid[c] + _grid[c+3] + _grid[c+6] != _magicConstant) isValid = false;
      }
      // Diags
      if(_grid[0] + _grid[4] + _grid[8] != _magicConstant) isValid = false;
      if(_grid[2] + _grid[4] + _grid[6] != _magicConstant) isValid = false;

      if (isValid) {
          setState(() {
             _isComplete = true;
             _score += 100;
          });
          _showWinDialog();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Board is full but sums are not 15!'), backgroundColor: Colors.orange));
         
         // Highlight errors briefly by clearing the board? No, let them fix it
      }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Magic Maintained!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Every row, column, and diagonal equals $_magicConstant.\n\nScore: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
             onPressed: () {
                Navigator.pop(context);
                for(int i=0; i<9; i++) {
                   if(!_isFixed[i]) _grid[i] = 0;
                }
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
              // Header with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      color: colorScheme.primary,
                      size: 28,
                    ),
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
              // Instructions
              _buildInstructionRow(theme, "1", "Fill the 3x3 grid with the numbers 1 through 9."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Use each number exactly once."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "The sum of every row, column, and both main diagonals must exactly equal the magic constant $_magicConstant."),
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
                        _buildMiniCell(theme, "2"),
                        const SizedBox(width: 4),
                        _buildMiniCell(theme, "9"),
                        const SizedBox(width: 4),
                        _buildMiniCell(theme, "4"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Valid Row",
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      "2 + 9 + 4 = 15",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Got it button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: Text(
                  "Let's Play!",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCell(ThemeData theme, String val) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Magic Square",
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
                Text("Magic Constant: $_magicConstant", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                   onPressed: _generatePuzzle, 
                   icon: const Icon(Icons.refresh, size: 18), 
                   label: const Text("Restart")
                ),
                TextButton.icon(
                  onPressed: _generatePuzzle,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: Text(
                    AppLocalizations.of(context)!.skip,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
             child: Center(
                child: AspectRatio(
                   aspectRatio: 1,
                   child: Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                         border: Border.all(color: theme.textTheme.bodyLarge!.color!, width: 4),
                         boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: GridView.builder(
                         physics: const NeverScrollableScrollPhysics(),
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                         ),
                         itemCount: 9,
                         itemBuilder: (context, index) {
                            int val = _grid[index];
                            bool isFixed = _isFixed[index];
                            bool isSelected = index == _selectedIdx;

                            return GestureDetector(
                               onTap: () => _onCellTap(index),
                               child: Container(
                                  decoration: BoxDecoration(
                                     border: Border.all(color: theme.dividerColor, width: 1),
                                     color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) 
                                           : (isFixed ? theme.cardColor : theme.scaffoldBackgroundColor),
                                  ),
                                  child: Center(
                                     child: Text(
                                        val == 0 ? "" : val.toString(),
                                        style: GoogleFonts.poppins(
                                           fontSize: 42,
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
                spacing: 12,
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
      bool isUsed = _grid.contains(num);
      return GestureDetector(
         onTap: isUsed ? null : () => _onNumberTap(num),
         child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
               color: isUsed ? theme.dividerColor.withOpacity(0.2) : theme.cardColor,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: isUsed ? Colors.transparent : theme.dividerColor),
               boxShadow: isUsed ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Center(
               child: Text(
                  num.toString(), 
                  style: GoogleFonts.poppins(
                     fontSize: 28, 
                     fontWeight: FontWeight.bold,
                     color: isUsed ? Colors.grey : theme.textTheme.bodyLarge?.color
                  )
               ),
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
