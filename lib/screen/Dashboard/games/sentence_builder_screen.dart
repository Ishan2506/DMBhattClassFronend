import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final MindGameService _gameService = MindGameService();

  List<GameQuestion> _allQuestions = [];
  int _currentIndex = 0;
  List<String> _currentWords = [];
  bool _isChecked = false;
  bool _isCorrect = false;
  int _score = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Sentence Builder');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allQuestions = data.map((json) => GameQuestion.fromJson(json)).toList();
          _allQuestions.shuffle();
          _isLoading = false;
        });
        if (_allQuestions.isNotEmpty) {
           _startLevel();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startLevel() {
    if (_allQuestions.isEmpty) return;
    
    setState(() {
      String sentence = _allQuestions[_currentIndex].questionText;
      _currentWords = sentence.split(' ');
      _currentWords.shuffle();
      // Ensure it's shuffled
      if (_currentWords.join(' ') == sentence) {
        _currentWords.shuffle();
      }
      _isChecked = false;
      _isCorrect = false;
    });
  }

  void _checkOrder() {
    if (_allQuestions.isEmpty) return;

    String targetSentence = _allQuestions[_currentIndex].questionText;
    String formedSentence = _currentWords.join(' ');
    bool correct = formedSentence == targetSentence;

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
      if (correct) {
        _score += 10;
      }
    });

    // Wait and move to next question regardless of correctness
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      
      if (_currentIndex < _allQuestions.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _startLevel();
      } else {
        _showWinDialog();
      }
    });
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
              _buildInstructionRow(theme, "1", "You will see words from a sentence in a jumbled order."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Drag and drop the words to arrange them into a meaningful, grammatically correct sentence."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Click 'Check Sentence' to verify your answer."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Use the hint icon if you need help with the word order."),
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
                    Text(
                      "Jumbled:",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildMiniWord(theme, "dog"),
                        _buildMiniWord(theme, "The"),
                        _buildMiniWord(theme, "barked"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.arrow_downward_rounded, color: theme.dividerColor, size: 20),
                    const SizedBox(height: 12),
                    Text(
                      "Correct Order:",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildMiniWord(theme, "The", isCorrect: true),
                        _buildMiniWord(theme, "dog", isCorrect: true),
                        _buildMiniWord(theme, "barked", isCorrect: true),
                      ],
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

  Widget _buildMiniWord(ThemeData theme, String val, {bool isCorrect = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green : theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? Colors.green : theme.dividerColor),
      ),
      child: Text(
        val, 
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold, 
          color: isCorrect ? Colors.white : theme.textTheme.bodyMedium?.color
        )
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("All Completed!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("You completed all sentences!\nFinal Score: $_score", style: GoogleFonts.poppins()),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               _restartGame();
             },
             child: const Text("Play Again"),
          )
        ],
      ),
    );
  }
  
  void _restartGame() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isCorrect = false;
      _isChecked = false;
      _allQuestions.shuffle();
      _isLoading = false;
    });
    _startLevel();
  }

  void _useHint() {
    if (_allQuestions.isEmpty) return;
    
    // Hint: Move the first correct word to the first position if not already
    String targetSentence = _allQuestions[_currentIndex].questionText;
    List<String> correctOrder = targetSentence.split(' ');
    
    // Find the first word that is out of place
    for (int i = 0; i < correctOrder.length; i++) {
      if (i >= _currentWords.length) break;
      
      if (_currentWords[i] != correctOrder[i]) {
        // Found mismatch at index i
        // Find where the correct word is
        int correctIndex = _currentWords.indexOf(correctOrder[i]);
        if (correctIndex != -1) {
            setState(() {
               // Swap
               String temp = _currentWords[i];
               _currentWords[i] = _currentWords[correctIndex];
               _currentWords[correctIndex] = temp;
            });
        }
        return; // Only one hint per click
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Sentence Builder", centerTitle: true),
        body: const CustomLoader(),
      );
    }
    
    if (_allQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Sentence Builder", centerTitle: true),
        body: Center(child: Text("No questions available", style: GoogleFonts.poppins())),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Sentence Builder",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb, color: Colors.amber),
            onPressed: () {
               if (!_isCorrect) _useHint();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _startLevel,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Level ${_currentIndex + 1}/${_allQuestions.length}", 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                ),
                Text(
                  "Score: $_score", 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber[800])
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Drag and drop words to form a correct sentence:",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ReorderableListView(
                      proxyDecorator: (child, index, animation) {
                         return Material(
                           elevation: 8,
                           borderRadius: BorderRadius.circular(12),
                           color: Colors.transparent,
                           child: child,
                         );
                      },
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _currentWords.removeAt(oldIndex);
                          _currentWords.insert(newIndex, item);
                          _isChecked = false;
                        });
                      },
                      children: [
                        for (int i = 0; i < _currentWords.length; i++)
                          Container(
                            key: ValueKey(_currentWords[i] + i.toString()), // Ensure unique key
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                                  blurRadius: 4, 
                                  offset: const Offset(0, 2)
                                )
                              ],
                              border: Border.all(color: theme.dividerColor.withOpacity(0.1))
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(Icons.drag_indicator, color: theme.dividerColor),
                              title: Text(
                                _currentWords[i],
                                style: GoogleFonts.poppins(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyLarge?.color
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isChecked)
            Container(
              padding: const EdgeInsets.all(16),
              color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              width: double.infinity,
              child: Text(
                _isCorrect ? "Correct! Well done." : "Not quite right yet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
               width: double.infinity,
               height: 55,
               child: ElevatedButton(
                 onPressed: _isChecked ? null : _checkOrder,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _isCorrect ? Colors.green : theme.colorScheme.primary,
                   foregroundColor: theme.colorScheme.onPrimary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 4
                 ),
                 child: Text(
                    _isCorrect ? "Next Sentence" : "Check Sentence",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }
}
