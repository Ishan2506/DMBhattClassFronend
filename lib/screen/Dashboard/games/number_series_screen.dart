import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class NumberSeriesScreen extends StatefulWidget {
  const NumberSeriesScreen({super.key});

  @override
  State<NumberSeriesScreen> createState() => _NumberSeriesScreenState();
}

class NumberSequence {
  final List<int> sequence;
  final int answer;
  final String ruleExplanation;

  NumberSequence(this.sequence, this.answer, this.ruleExplanation);
}

class _NumberSeriesScreenState extends State<NumberSeriesScreen> {
  final MindGameService _gameService = MindGameService();

  late NumberSequence _currentSequence;
  int _score = 0;
  String _currentInput = "";
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _generateSequence();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _generateSequence() {
     // Generate a random math sequence type
     int type = _rand.nextInt(6);
     List<int> seq = [];
     int ans = 0;
     String rule = "";

     switch (type) {
        case 0: // Arithmetic progression (add a constant)
            int start = _rand.nextInt(20) + 1;
            int step = _rand.nextInt(15) + 2;
            for(int i=0; i<5; i++) seq.add(start + (i * step));
            ans = start + (5 * step);
            rule = "Add $step to the previous number.";
            break;
        case 1: // Geometric progression (multiply by a constant)
            int start = _rand.nextInt(5) + 1;
            int step = _rand.nextInt(3) + 2;
            for(int i=0; i<5; i++) seq.add(start * pow(step, i).toInt());
            ans = start * pow(step, 5).toInt();
            rule = "Multiply the previous number by $step.";
            break;
        case 2: // Arithmetic with increasing step
            int start = _rand.nextInt(10) + 1;
            int current = start;
            int step = _rand.nextInt(5) + 1;
            for(int i=0; i<5; i++) {
               seq.add(current);
               current += step;
               step += 1; // Step increases by 1 each time
            }
            ans = current;
            rule = "Add an increasing number each time (+step+1, +step+2...).";
            break;
        case 3: // Fibonacci style
            int a = _rand.nextInt(5) + 1;
            int b = _rand.nextInt(5) + 1;
            seq.addAll([a, b]);
            for(int i=2; i<5; i++) {
               seq.add(seq[i-1] + seq[i-2]);
            }
            ans = seq[4] + seq[3];
            rule = "Add the previous two numbers together.";
            break;
        case 4: // Squares / Cubes modified
            int offset = _rand.nextBool() ? 1 : -1;
            int power = _rand.nextBool() ? 2 : 3;
            int start = _rand.nextInt(3) + 1;
            for(int i=0; i<5; i++) {
                seq.add(pow(start + i, power).toInt() + offset);
            }
            ans = pow(start + 5, power).toInt() + offset;
            rule = "${power == 2 ? 'Squares' : 'Cubes'} of consecutive numbers ${offset > 0 ? 'plus 1' : 'minus 1'}.";
            break;
        case 5: // Alternating operation (e.g., *2, -1, *2, -1)
            int start = _rand.nextInt(5) + 2;
            int mult = _rand.nextInt(2) + 2;
            int sub = _rand.nextInt(3) + 1;
            int current = start;
            for(int i=0; i<5; i++) {
               seq.add(current);
               if(i % 2 == 0) current *= mult;
               else current -= sub;
            }
            ans = current;
            rule = "Alternate multiplying by $mult and subtracting $sub.";
            break;
     }

     setState(() {
        _currentSequence = NumberSequence(seq, ans, rule);
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
      // Don't let input get astronomically huge
      if (_currentInput.length < 6) {
         setState(() => _currentInput += val);
      }
    }
  }

  void _checkAnswer() {
    int? inputInt = int.tryParse(_currentInput);
    
    if (inputInt == _currentSequence.answer) {
      setState(() {
         _score += 100;
      });
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect. Try again!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Correct!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text("Rule:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text(_currentSequence.ruleExplanation, style: GoogleFonts.poppins()),
           ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateSequence();
            },
            child: const Text("Next Sequence"),
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
        content: Text("Find the mathematical rule that governs the sequence of numbers shown. Enter the number that should come next in the sequence.", style: GoogleFonts.poppins()),
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
        title: "Number Series",
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
                  Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                     onPressed: () {
                        setState(() { _score = 0; });
                        _generateSequence();
                     }, 
                     icon: const Icon(Icons.skip_next), 
                     label: const Text("Skip")
                  ),
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
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                         ),
                         child: Center(
                            child: Wrap(
                               spacing: 12,
                               runSpacing: 12,
                               crossAxisAlignment: WrapCrossAlignment.center,
                               children: [
                                  ..._currentSequence.sequence.map((n) => _buildSequenceTag(n.toString(), theme)),
                                  _buildSequenceTag("?", theme, isQuestion: true),
                               ]
                            ),
                         ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Answer Display
                      Container(
                         width: 200,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2)),
                         ),
                         child: Center(
                            child: Text(
                               _currentInput.isEmpty ? "Enter Number" : _currentInput,
                               style: GoogleFonts.poppins(
                                  fontSize: 32, 
                                  fontWeight: FontWeight.bold,
                                  color: _currentInput.isEmpty ? Colors.grey : theme.textTheme.bodyLarge?.color,
                               ),
                            ),
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
                           _buildNumpadBtn("-", theme, color: Colors.blue.shade50, textColor: Colors.blue.shade800), // In case answer is negative
                           _buildNumpadBtn("0", theme),
                           _buildNumpadBtn("<", theme, color: Colors.red.shade50, textColor: Colors.red.shade800),
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

  Widget _buildSequenceTag(String text, ThemeData theme, {bool isQuestion = false}) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
           color: isQuestion ? theme.colorScheme.primary : theme.scaffoldBackgroundColor,
           borderRadius: BorderRadius.circular(8),
           border: isQuestion ? null : Border.all(color: theme.dividerColor),
        ),
        child: Text(
           text,
           style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isQuestion ? Colors.white : theme.textTheme.bodyLarge?.color,
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
