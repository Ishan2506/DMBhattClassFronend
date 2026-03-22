import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

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

  factory NumberSequence.fromGameQuestion(GameQuestion q) {
    // Expecting sequence as comma-separated ints or in questionText
    // But usually for Number Series, questionText contains "2, 4, 6, 8"
    List<int> seq = q.questionText.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    return NumberSequence(
      seq,
      int.tryParse(q.correctAnswer) ?? 0,
      q.meta['hint'] ?? "",
    );
  }
}

class _NumberSeriesScreenState extends State<NumberSeriesScreen> {
  final MindGameService _gameService = MindGameService();

  List<NumberSequence> _sequences = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  NumberSequence? _currentSequence;
  int _score = 0;
  String _currentInput = "";
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Number Series');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sequences = data.map((json) => NumberSequence.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          if (_sequences.isNotEmpty) {
            _sequences.shuffle();
            _currentIndex = 0;
            _currentSequence = _sequences[_currentIndex];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching number series: $e");
      setState(() => _isLoading = false);
    }
  }

  void _nextSequence() {
    if (_currentIndex < _sequences.length - 1) {
      setState(() {
        _currentIndex++;
        _currentSequence = _sequences[_currentIndex];
        _currentInput = "";
        _textController.clear();
      });
    } else {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Series Master!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("You solved all the number sequences!\n\nFinal Score: $_score", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sequences.shuffle();
                _currentIndex = 0;
                _currentSequence = _sequences[_currentIndex];
                _score = 0;
                _currentInput = "";
              });
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

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }




  void _checkAnswer() {
    if (_currentSequence == null) return;
    int? inputInt = int.tryParse(_currentInput);
    
    if (inputInt == _currentSequence!.answer) {
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
    if (_currentSequence == null) return;
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
              Text(_currentSequence!.ruleExplanation, style: GoogleFonts.poppins()),
           ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextSequence();
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
      body: _isLoading 
          ? const CustomLoader()
          : _sequences.isEmpty
            ? Center(child: Text("No number series found.", style: GoogleFonts.poppins()))
            : Column(
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
                        _nextSequence();
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
                                  if (_currentSequence != null) ..._currentSequence!.sequence.map((n) => _buildSequenceTag(n.toString(), theme)),
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
