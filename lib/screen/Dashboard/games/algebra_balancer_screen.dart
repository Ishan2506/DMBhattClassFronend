import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class AlgebraBalancerScreen extends StatefulWidget {
  const AlgebraBalancerScreen({super.key});

  @override
  State<AlgebraBalancerScreen> createState() => _AlgebraBalancerScreenState();
}

class AlgebraProblem {
   final List<String> equations; // For display, e.g., ["🍎 + 🍎 = 10", "🍎 + 🍌 = 8"]
   final String? questionRow; // Special final row if needed, otherwise empty
   final int answer;
   final String? hint;

   AlgebraProblem({required this.equations, this.questionRow, required this.answer, this.hint});
}

class _AlgebraBalancerScreenState extends State<AlgebraBalancerScreen> {
  final MindGameService _gameService = MindGameService();

  AlgebraProblem? _currentProblem;
  List<dynamic> _dynamicProblems = [];
  int _currentProblemIndex = 0;
  bool _isLoading = true;
  String _error = "";

  int _score = 0;
  int _level = 1;
  String _currentInput = "";
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchDynamicProblems();
  }

  Future<void> _fetchDynamicProblems() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });
    try {
      final response = await ApiService.getGameQuestions('Algebra Balancer');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _dynamicProblems = data;
            _dynamicProblems.shuffle();
            _currentProblemIndex = 0;
            _loadProblem();
          });
        } else {
          setState(() => _error = "No questions available yet. Please check back later!");
        }
      } else {
        setState(() => _error = "Failed to load questions. Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadProblem() {
    if (_dynamicProblems.isEmpty) return;
    
    final q = _dynamicProblems[_currentProblemIndex];
    final String questionText = q['questionText'] ?? "";
    final String correctAnswer = q['correctAnswer'] ?? "0";
    final String? hint = q['meta'] != null ? q['meta']['hint'] : null;

    // Split multi-line questionText into equations
    List<String> eqs = questionText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // If it's a single line and contains '=', it's just the problem. 
    // If we want a specific question row feel, we can pop the last one if it ends with '?'
    String? qRow;
    if (eqs.isNotEmpty && eqs.last.contains('?')) {
       qRow = eqs.removeLast().replaceAll('=', '').replaceAll('?', '').trim();
    }

    setState(() {
      _currentProblem = AlgebraProblem(
        equations: eqs,
        questionRow: qRow,
        answer: int.tryParse(correctAnswer) ?? 0,
        hint: hint,
      );
      _currentInput = "";
      _textController.clear();
    });
  }

  void _nextProblem() {
    if (_dynamicProblems.isEmpty) return;
    setState(() {
      _currentProblemIndex = (_currentProblemIndex + 1) % _dynamicProblems.length;
      _loadProblem();
    });
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_currentProblem == null) return;
    int? inputInt = int.tryParse(_currentInput);
    
    if (inputInt == _currentProblem!.answer) {
      _showSuccessDialog();
    } else {
      String msg = "Incorrect.";
      if (_currentProblem!.hint != null) {
        msg += " Hint: ${_currentProblem!.hint}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
        title: Text("Correct!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Text("Great job solving this algebra puzzle!", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextProblem();
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
                  Text("How to Play", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", "Solve the equations to find the value of each variable or emoji."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Use logic and arithmetic to deduce the numbers."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Enter the final answer and press Submit."),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Got it!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
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
          width: 24, height: 24,
          decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text(number, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, fontSize: 12))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13, height: 1.4))),
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
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: _showHowToPlay),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const CustomLoader()
          : _error.isNotEmpty
            ? Center(child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(_error, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
              ))
            : Column(
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
                                children: _currentProblem!.equations.map((eq) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(eq, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
                                )).toList(),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Question Row
                            if (_currentProblem!.questionRow != null || (_currentProblem!.equations.isEmpty))
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
                                    if (_currentProblem!.questionRow != null)
                                      Text(_currentProblem!.questionRow!, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text("=", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentInput.isEmpty ? "?" : _currentInput,
                                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _currentInput.isEmpty ? Colors.grey : theme.colorScheme.primary),
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
                                  filled: true,
                                  fillColor: theme.cardColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
                                ),
                                onChanged: (val) => setState(() => _currentInput = val),
                                onSubmitted: (_) {
                                  if (_currentInput.isNotEmpty && _currentInput != "-") _checkAnswer();
                                },
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: ElevatedButton(
                                onPressed: _currentInput.isEmpty || _currentInput == "-" ? null : _checkAnswer,
                                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text("Submit Answer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _nextProblem,
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
