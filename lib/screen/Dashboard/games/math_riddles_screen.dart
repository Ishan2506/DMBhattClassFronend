import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class MathRiddlesScreen extends StatefulWidget {
  const MathRiddlesScreen({super.key});

  @override
  State<MathRiddlesScreen> createState() => _MathRiddlesScreenState();
}

class MathRiddle {
  final String question;
  final String answer;
  final String hint;

  MathRiddle({required this.question, required this.answer, required this.hint});

  factory MathRiddle.fromGameQuestion(GameQuestion q) {
    return MathRiddle(
      question: q.questionText,
      answer: q.correctAnswer,
      hint: q.meta['hint'] ?? "",
    );
  }
}

class _MathRiddlesScreenState extends State<MathRiddlesScreen> {
  final MindGameService _gameService = MindGameService();

  int _currentIndex = 0;
  int _score = 0;
  String _currentInput = "";
  bool _showHint = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<MathRiddle> _riddles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Math Riddles');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _riddles = data.map((json) => MathRiddle.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          _riddles.shuffle();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching riddles: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_currentInput == _riddles[_currentIndex].answer) {
      _handleCorrectAnswer();
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

  void _handleCorrectAnswer() {
    setState(() {
      _score += _showHint ? 50 : 100; // Less points if hint was used
      
      if (_currentIndex < _riddles.length - 1) {
        _currentIndex++;
        _currentInput = "";
        _textController.clear();
        _showHint = false;
      } else {
        _showWinDialog();
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Genius Level Reached!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You solved all the math riddles!\n\nFinal Score: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
               setState(() {
                  _riddles.shuffle();
                  _currentIndex = 0;
                  _score = 0;
                  _currentInput = "";
                  _showHint = false;
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
              _buildInstructionRow(theme, "1", "Read the math riddle carefully on the screen."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Type your answer using the numpad provided."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap Submit Answer when you're ready."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Stuck? You can use a hint, but it will cost you points!"),
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
                      "Example Riddle",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "What 3 positive numbers give the same result when multiplied and added together?",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.arrow_downward_rounded, color: theme.dividerColor, size: 20),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "123 (1+2+3 = 6, 1*2*3 = 6)",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
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
        title: "Math Riddles",
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
        : _riddles.isEmpty
          ? Center(child: Text("No riddles found", style: GoogleFonts.poppins()))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Riddle ${_currentIndex + 1}/${_riddles.length}", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
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
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                _riddles[_currentIndex].question,
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            if (_showHint)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _riddles[_currentIndex].hint,
                                        style: GoogleFonts.poppins(color: Colors.amber.shade900),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => setState(() => _showHint = true), 
                                icon: const Icon(Icons.help_outline), 
                                label: const Text("Show Hint (-50 pts)")
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
                              onPressed: () {
                                if (_currentIndex < _riddles.length - 1) {
                                  setState(() {
                                    _currentIndex++;
                                    _currentInput = "";
                                    _textController.clear();
                                    _showHint = false;
                                  });
                                } else {
                                  _showWinDialog();
                                }
                              },
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
