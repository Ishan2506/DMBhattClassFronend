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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How to Play", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("1. You will see words from a sentence in a jumbled order.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Drag and drop the words to arrange them into a meaningful sentence.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Click 'Check Sentence' to verify your answer.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("4. Use the hint icon if you need help with the word order.", style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
        ],
      ),
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
