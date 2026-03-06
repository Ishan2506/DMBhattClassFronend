import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class AlgebraBalancerScreen extends StatefulWidget {
  const AlgebraBalancerScreen({super.key});

  @override
  State<AlgebraBalancerScreen> createState() => _AlgebraBalancerScreenState();
}

class EmojiVariable {
  final String emoji;
  final int value;
  EmojiVariable(this.emoji, this.value);
}

class AlgebraProblem {
   final List<EmojiVariable> variables;
   final List<String> equations; // For display, e.g., "🍎 + 🍎 = 10"
   final List<String> questionRow; // The row to solve, e.g., ["🍎", "+", "🍌", "*", "🍉"]
   final int answer;

   AlgebraProblem(this.variables, this.equations, this.questionRow, this.answer);
}

class _AlgebraBalancerScreenState extends State<AlgebraBalancerScreen> {
  final MindGameService _gameService = MindGameService();

  late AlgebraProblem _currentProblem;
  int _score = 0;
  int _level = 1;
  String _currentInput = "";
  final Random _rand = Random();

  final List<String> _emojis = ["🍎", "🍌", "🍉", "🍇", "🍓", "🍒", "🍩", "🍕", "🍔", "🍟", "🚗", "🚲", "✈️", "🚀", "🐶", "🐱", "🐰", "🦊"];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _generateProblem();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _generateProblem() {
     _emojis.shuffle();
     
     // 3 variables
     EmojiVariable var1 = EmojiVariable(_emojis[0], _rand.nextInt(9) + 2); // 2-10
     EmojiVariable var2 = EmojiVariable(_emojis[1], _rand.nextInt(9) + 2);
     EmojiVariable var3 = EmojiVariable(_emojis[2], _rand.nextInt(9) + 2);

     List<String> eqs = [];
     
     // Eq 1: var1 + var1 + var1 = X
     int val1 = var1.value * 3;
     eqs.add("${var1.emoji} + ${var1.emoji} + ${var1.emoji} = $val1");
     
     // Eq 2: var1 + var2 + var2 = Y
     int val2 = var1.value + (var2.value * 2);
     eqs.add("${var1.emoji} + ${var2.emoji} + ${var2.emoji} = $val2");
     
     // Eq 3: var2 - var3 = Z OR var2 + var3 = Z
     bool isAdd = _rand.nextBool();
     if (isAdd) {
        int val3 = var2.value + var3.value;
        eqs.add("${var2.emoji} + ${var3.emoji} = $val3");
     } else {
        // Ensure var2 > var3 to avoid negative for simplicity if we want, OR just let it be
        if (var2.value <= var3.value) {
           var3 = EmojiVariable(_emojis[2], _rand.nextInt(var2.value - 1) + 1); // Make var3 smaller
        }
        int val3 = var2.value - var3.value;
        eqs.add("${var2.emoji} - ${var3.emoji} = $val3");
     }
     
     // Eq 4: Question -> var1 + var2 * var3 = ?
     int ans = var1.value + (var2.value * var3.value); // Order of operations matters!
     List<String> qRow = [var1.emoji, "+", var2.emoji, "×", var3.emoji];

     setState(() {
        _currentProblem = AlgebraProblem([var1, var2, var3], eqs, qRow, ans);
        _currentInput = "";
     });
  }

  void _onNumpadTap(String val) {
    if (val == "C") {
      setState(() => _currentInput = "");
    } else if (val == "<") {
      setState(() {
        if (_currentInput.isNotEmpty) {
           _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      });
    } else {
      if (_currentInput.length < 5) {
         setState(() => _currentInput += val);
      }
    }
  }

  void _checkAnswer() {
    int? inputInt = int.tryParse(_currentInput);
    
    if (inputInt == _currentProblem.answer) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect. Remember Order of Operations (Multiply first)!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    setState(() {
       _score += 100;
       _level++;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Perfect Balance!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Text("You correctly deduced the values and applied the order of operations.", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateProblem();
            },
            child: const Text("Next Level"),
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
            Text("1. Deduce the numbers hidden behind the emojis by solving the first three equations.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Once you know what number each emoji represents, solve the final question row.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. TRICKY PART: Remember the standard mathematical order of operations (BODMAS/PEMDAS). Multiplication (×) comes BEFORE Addition (+).", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
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
        title: "Algebra Balancer",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Level: $_level", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                  Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                      Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                         ),
                         child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _currentProblem.equations.map((eq) => Padding(
                               padding: const EdgeInsets.only(bottom: 16.0),
                               child: Text(eq, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                            )).toList(),
                         ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Question Row
                      Container(
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                         decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300, width: 2),
                         ),
                         child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               ..._currentProblem.questionRow.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(item, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                               )),
                               Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text("=", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                               ),
                               Text(
                                  _currentInput.isEmpty ? "?" : _currentInput,
                                  style: GoogleFonts.poppins(
                                     fontSize: 28, 
                                     fontWeight: FontWeight.bold,
                                     color: _currentInput.isEmpty ? Colors.grey : theme.colorScheme.primary,
                                  ),
                               ),
                            ],
                         ),
                      ),
                   ],
                ),
              ),
             ),
            ),
            
            // Custom Numpad
            Container(
               padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
               child: Column(
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("1", theme),
                           _buildNumpadBtn("2", theme),
                           _buildNumpadBtn("3", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("4", theme),
                           _buildNumpadBtn("5", theme),
                           _buildNumpadBtn("6", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("7", theme),
                           _buildNumpadBtn("8", theme),
                           _buildNumpadBtn("9", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("-", theme, color: Colors.blue.shade50, textColor: Colors.blue.shade800),
                           _buildNumpadBtn("0", theme),
                           _buildNumpadBtn("<", theme, color: Colors.grey.shade200, textColor: Colors.grey.shade800),
                        ],
                     ),
                     const SizedBox(height: 12),
                     ElevatedButton(
                        onPressed: _currentInput.isEmpty || _currentInput == "-" ? null : _checkAnswer,
                        style: ElevatedButton.styleFrom(
                           minimumSize: const Size(double.infinity, 56),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Submit Answer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                     )
                  ],
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadBtn(String label, ThemeData theme, {Color? color, Color? textColor}) {
     return InkWell(
        onTap: () => _onNumpadTap(label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
           width: MediaQuery.of(context).size.width * 0.22,
           height: 60,
           decoration: BoxDecoration(
              color: color ?? theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
           ),
           child: Center(
              child: label == "<" 
                 ? Icon(Icons.backspace_outlined, color: textColor ?? theme.textTheme.bodyLarge?.color)
                 : Text(
                     label, 
                     style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: textColor ?? theme.textTheme.bodyLarge?.color,
                     )
                   ),
           ),
        ),
     );
  }
}
