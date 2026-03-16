import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

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
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
    _textController.dispose();
    _focusNode.dispose();
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
        _textController.clear();
     });
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
                      color: colorScheme.primary.withValues(alpha: 0.1),
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
              _buildInstructionRow(theme, "1", "Deduce the numbers hidden behind emojis by solving the first 3 equations."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Once you know what number each emoji represents, solve the final question row."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "TRICKY PART: Remember the standard mathematical order of operations (BODMAS/PEMDAS)."),
              const SizedBox(height: 24),
              // Example Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.5)),
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
                    const SizedBox(height: 8),
                    Text(
                      "🍎 = 3, 🍌 = 2",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "🍎 + 🍎 × 🍌 = ?",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_downward_rounded, size: 20, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      "3 + (3 × 2) = 9",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
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

  Widget _buildInstructionRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
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
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
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
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
                            color: Colors.blue.withValues(alpha: 0.1),
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

                      // Input Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: TextField(
                           controller: _textController,
                           focusNode: _focusNode,
                           keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                           style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                           textAlign: TextAlign.center,
                           decoration: InputDecoration(
                              hintText: "Enter your answer",
                              hintStyle: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade400, letterSpacing: 0),
                              filled: true,
                              fillColor: theme.cardColor,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(16),
                                 borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(16),
                                 borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(16),
                                 borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                              ),
                           ),
                           onChanged: (val) {
                              setState(() {
                                 _currentInput = val;
                              });
                           },
                           onSubmitted: (_) {
                              if (_currentInput.isNotEmpty && _currentInput != "-") {
                                 _checkAnswer();
                              }
                           },
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ElevatedButton(
                           onPressed: _currentInput.isEmpty || _currentInput == "-" ? null : _checkAnswer,
                           style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           child: Text("Submit Answer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _generateProblem,
                        child: Text(
                          AppLocalizations.of(context)!.skip,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                   ],
                ),
              ),
             ),
            ),
          ],
        ),
      ),
    );
  }
}
