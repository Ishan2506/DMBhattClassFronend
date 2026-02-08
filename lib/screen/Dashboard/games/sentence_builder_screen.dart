import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final MindGameService _gameService = MindGameService();

  // List of sentences to unscramble
  final List<String> _sentences = [
    "Honesty is the best policy",
    "Practice makes a man perfect",
    "A stitch in time saves nine",
    "Actions speak louder than words",
    "The quick brown fox jumps over the lazy dog",
    "Education is the most powerful weapon",
    "Better late than never",
    "Slow and steady wins the race",
    "Reading is to the mind what exercise is to the body",
    "Flutter is an open source framework by Google"
  ];

  int _currentIndex = 0;
  List<String> _currentWords = [];
  bool _isChecked = false;
  bool _isCorrect = false;
  int _score = 0;
  
  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _sentences.shuffle();
    _startLevel();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startLevel() {
    setState(() {
      _currentWords = _sentences[_currentIndex].split(' ');
      _currentWords.shuffle();
      // Ensure it's shuffled
      if (_currentWords.join(' ') == _sentences[_currentIndex]) {
        _currentWords.shuffle();
      }
      _isChecked = false;
      _isCorrect = false;
    });
  }

  void _checkOrder() {
    String formedSentence = _currentWords.join(' ');
    bool correct = formedSentence == _sentences[_currentIndex];

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
      if (correct) {
        _score += 10;
      }
    });

    if (correct) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_currentIndex < _sentences.length - 1) {
            setState(() {
              _currentIndex++;
            });
            _startLevel();
          } else {
            _showWinDialog();
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect! Try rearranging the words.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
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
          )
        ],
      ),
    );
  }

  void _useHint() {
    // Hint: Move the first correct word to the first position if not already
    String targetSentence = _sentences[_currentIndex];
    List<String> correctOrder = targetSentence.split(' ');
    
    // Find the first word that is out of place
    for (int i = 0; i < correctOrder.length; i++) {
      if (_currentWords[i] != correctOrder[i]) {
        // Found mismatch at index i
        // Find where the correct word is
        int correctIndex = _currentWords.indexOf(correctOrder[i]);
        setState(() {
           // Swap
           String temp = _currentWords[i];
           _currentWords[i] = _currentWords[correctIndex];
           _currentWords[correctIndex] = temp;
        });
        return; // Only one hint per click
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Sentence Builder",
        centerTitle: true,
        actions: [
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
            color: theme.primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Level ${_currentIndex + 1}/${_sentences.length}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                Text("Score: $_score", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber[800])),
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
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
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
                            key: ValueKey(_currentWords[i] + i.toString()), // Unique key handles duplicate words
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              border: Border.all(color: Colors.grey.shade200)
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(Icons.drag_indicator, color: Colors.grey[400]),
                              title: Text(
                                _currentWords[i],
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.normal),
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
              color: _isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              width: double.infinity,
              child: Text(
                _isCorrect ? "Correct! Well done." : "Not quite right yet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _isCorrect ? Colors.green[800] : Colors.red[800],
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
                 onPressed: _isCorrect ? null : _checkOrder,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _isCorrect ? Colors.green : theme.primaryColor,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 4
                 ),
                 child: Text(
                    _isCorrect ? "Next Sentence" : "Check Sentence",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }
}
