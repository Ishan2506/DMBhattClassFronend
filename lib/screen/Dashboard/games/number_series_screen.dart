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
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _generateSequence();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    _focusNode.dispose();
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
            for(int i=0; i<5; i++) {
              seq.add(start + (i * step));
            }
            ans = start + (5 * step);
            rule = "Add $step to the previous number.";
            break;
        case 1: // Geometric progression (multiply by a constant)
            int start = _rand.nextInt(5) + 1;
            int step = _rand.nextInt(3) + 2;
            for(int i=0; i<5; i++) {
              seq.add(start * pow(step, i).toInt());
            }
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
               if(i % 2 == 0) {
                 current *= mult;
               } else {
                 current -= sub;
               }
            }
            ans = current;
            rule = "Alternate multiplying by $mult and subtracting $sub.";
            break;
     }

     setState(() {
        _currentSequence = NumberSequence(seq, ans, rule);
        _currentInput = "";
        _textController.clear();
     });
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
              _buildInstructionRow(theme, "1", "Find the mathematical rule that governs the sequence of numbers shown."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Use the numpad to enter the number that should come next."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Submit your answer to score points!"),
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
                    const SizedBox(height: 12),
                    Text(
                      "2, 4, 6, 8, ?",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Rule: Add 2 to the previous number.",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Answer: 10",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
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
                      const SizedBox(height: 48),
                      Container(
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
                      
                      // Input Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      
                      const SizedBox(height: 24),
                      
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


}
