import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class WordBridgeScreen extends StatefulWidget {
  const WordBridgeScreen({super.key});

  @override
  State<WordBridgeScreen> createState() => _WordBridgeScreenState();
}

class _WordBridgeScreenState extends State<WordBridgeScreen> {
  final MindGameService _gameService = MindGameService();

  // Defines a level: Start Word, Target Word, and a sequence of choices.
  // Each step has `options` and the `correct` choice which becomes the next "Current Word".
  final List<Map<String, dynamic>> _levels = [
    {
      "start": "Rain",
      "target": "Bread",
      "path": ["Rain", "Water", "Flour", "Bread"],
      "options_pool": [
        ["Cloud", "Water", "Umbrella"], // Rain -> ?
        ["Fire", "Flour", "Ice"],       // Water -> ?
        ["Sandwich", "Dough", "Bread"]  // Flour -> ? (Flour makes Bread)
      ]
    },
    // Let's refine the logic to be "Connect the concepts"
    {
      "start": "Forest",
      "target": "Table",
      "path": ["Forest", "Tree", "Wood", "Table"],
      "options_pool": [
        ["River", "Tree", "Mountain"], // Forest -> ?
        ["Leaf", "Wood", "Root"],      // Tree -> ?
        ["Table", "Paper", "Ash"]      // Wood -> ?
      ]
    },
    {
      "start": "Cow",
      "target": "Omelette",
      "path": ["Cow", "Grass", "Chicken", "Egg", "Omelette"], 
      // Cow eats Grass ?? No. 
      // Cow -> Milk -> Cheese -> Omelette? Yes.
      // Cow -> Milk -> Cheese -> Omelette.
      "options_pool": [
        ["Milk", "Beef", "Leather"],   // Cow -> ?
        ["Cheese", "Yogurt", "White"], // Milk -> ?
        ["Pizza", "Mouse", "Omelette"] // Cheese -> ? (Cheesy Omelette) or maybe closer relation.
      ]
    },
    {
       "start": "Sand",
       "target": "Window",
       "path": ["Sand", "Glass", "Window"],
       "options_pool": [
         ["Beach", "Glass", "Desert"], // Sand -> ?
         ["Door", "Wall", "Window"]    // Glass -> ?
       ]
    },
    {
       "start": "Sun",
       "target": "Toast",
       "path": ["Sun", "Heat", "Toaster", "Toast"],
       "options_pool": [
         ["Moon", "Heat", "Star"],     // Sun -> ?
         ["Cold", "Toaster", "Oven"],  // Heat -> ?
         ["Bread", "Butter", "Toast"]  // Toaster -> ?
       ]
    }
  ];

  int _currentLevelIndex = 0;
  int _currentStepIndex = 0;
  String _currentWord = "";
  bool _isGameOver = false;
  int _score = 0;
  bool _showFeedback = false;
  bool _lastChoiceCorrect = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startLevel();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startLevel() {
    setState(() {
      _currentWord = _levels[_currentLevelIndex]["start"];
      _currentStepIndex = 0;
      _showFeedback = false;
    });
  }

  void _handleOptionTap(String option) {
    if (_showFeedback) return;

    // Determine correct answer for current step
    // The "path" array has the full chain: [Start, Step1, Step2, ..., Target]
    // _currentStepIndex 0 corresponds to finding path[1]
    
    List<String> path = _levels[_currentLevelIndex]["path"] as List<String>;
    String correctAnswer = path[_currentStepIndex + 1];

    bool correct = (option == correctAnswer);

    setState(() {
      _showFeedback = true;
      _lastChoiceCorrect = correct;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showFeedback = false;
        if (correct) {
          _score += 10;
          _currentWord = correctAnswer;
          _currentStepIndex++;
          
          // Check if reached target
          if (_currentWord == _levels[_currentLevelIndex]["target"]) {
            _nextLevel();
          }
        } else {
           // Wrong choice feedback handled, just reset feedback to let them try again?
           // Or restart level? Let's just let them try again.
        }
      });
    });
  }

  void _nextLevel() {
    if (_currentLevelIndex < _levels.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chain Complete! Next Level..."), backgroundColor: Colors.green, duration: Duration(milliseconds: 800))
      );
      setState(() {
        _currentLevelIndex++;
        _startLevel();
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
        title: Text("Bridge Built!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("You connected all the concepts!\nFinal Score: $_score", style: GoogleFonts.poppins()),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelData = _levels[_currentLevelIndex];
    final target = levelData["target"];
    final optionsPool = levelData["options_pool"] as List<List<String>>;
    
    // Safety check
    if (_currentStepIndex >= optionsPool.length) return const SizedBox();

    final currentOptions = optionsPool[_currentStepIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Word Bridge",
        centerTitle: true,
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text("Score: $_score", style: const TextStyle(fontWeight: FontWeight.bold))))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             // Progress
             LinearProgressIndicator(
               value: (_currentLevelIndex + 1) / _levels.length,
               backgroundColor: Colors.grey.shade300,
               color: theme.primaryColor,
             ),
             const SizedBox(height: 40),
             
             // Bridge Visualization
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildStone(_levels[_currentLevelIndex]["start"], isActive: true, theme: theme),
                 Expanded(child: Divider(thickness: 2, color: Colors.grey.shade300, indent: 10, endIndent: 10)),
                 Icon(Icons.flag, color: theme.primaryColor),
                 Expanded(child: Divider(thickness: 2, color: Colors.grey.shade300, indent: 10, endIndent: 10)),
                 _buildStone(target, isActive: false, theme: theme), // Target
               ],
             ),
             
             const Spacer(),
             
             Text(
               "Current Concept:",
               style: GoogleFonts.poppins(color: Colors.grey[600]),
             ),
             const SizedBox(height: 8),
             Text(
               _currentWord,
               style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
             ),
             const SizedBox(height: 8),
             const Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
             const SizedBox(height: 8),
             Text(
               "Connects to...",
               style: GoogleFonts.poppins(color: Colors.grey[600]),
             ),
             
             const Spacer(),
             
             // Options
             ...currentOptions.map((opt) {
                // Determine feedback color
                Color btnColor = Colors.white;
                if (_showFeedback) {
                   List<String> path = _levels[_currentLevelIndex]["path"] as List<String>;
                   String correct = path[_currentStepIndex + 1];
                   if (opt == correct) btnColor = Colors.green.shade100;
                   if (opt != correct && _lastChoiceCorrect == false) btnColor = Colors.transparent; // Don't highlight wrong ones, simple
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleOptionTap(opt),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: btnColor,
                        shadowColor: Colors.black12,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: theme.primaryColor.withOpacity(0.2))
                      ),
                      child: Text(
                        opt, 
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ),
                );
             }).toList(),
             
             const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStone(String text, {required bool isActive, required ThemeData theme}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? theme.primaryColor : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Icon(isActive ? Icons.hub : Icons.place, color: isActive ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14))
      ],
    );
  }
}
