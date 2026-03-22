import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class WordBridgeScreen extends StatefulWidget {
  const WordBridgeScreen({super.key});

  @override
  State<WordBridgeScreen> createState() => _WordBridgeScreenState();
}

class _WordBridgeScreenState extends State<WordBridgeScreen> {
  final MindGameService _gameService = MindGameService();

  List<GameQuestion> _allQuestions = [];
  int _currentIndex = 0;
  String _currentWord = "";
  int _score = 0;
  bool _showFeedback = false;
  bool _lastChoiceCorrect = false;
  String _selectedOption = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Word Bridge');
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
      debugPrint("Error fetching questions: $e");
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
    
    // For Word Bridge, we split the analogy "A : B :: C : ?"
    // questionText = "Photosynthesis : Chlorophyll :: Respiration : ?"
    // _currentWord becomes the part before the bridge "Respiration" (from text or logic)
    // Actually, let's keep it simple: Show the whole analogy but highlight the current challenge word.
    
    final q = _allQuestions[_currentIndex];
    final text = q.questionText;
    final parts = text.split("::");
    
    setState(() {
      if (parts.length > 1) {
        // "Respiration : ?"
        _currentWord = parts[1].split(":")[0].trim();
      } else {
        _currentWord = text;
      }
      _showFeedback = false;
    });
  }

  void _handleOptionTap(String option) {
    if (_showFeedback || _allQuestions.isEmpty) return;

    final question = _allQuestions[_currentIndex];
    bool correct = (option == question.correctAnswer);

    setState(() {
      _showFeedback = true;
      _lastChoiceCorrect = correct;
      _selectedOption = option;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      if (correct) {
        _score += 10;
      }
      
      setState(() {
        _showFeedback = false;
        _selectedOption = "";
      });

      // Move to next question even if wrong, to allow progression
      _nextLevel();
    });
  }

  void _nextLevel() {
    if (_currentIndex < _allQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _startLevel();
      });
    } else {
      _showWinDialog();
    }
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
              _buildInstructionRow(theme, "1", "You will see an analogy: A is to B as C is to ?"),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Understand the relationship between the first pair of words."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Choose the option that completes the second pair with the same relationship."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Build the bridge by connecting all the concepts!"),
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
                      "Example Analogy",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tree is to Leaf as \nFlower is to ?",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_downward_rounded, color: theme.dividerColor, size: 20),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Petal",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
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
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Word Bridge", centerTitle: true),
        body: CustomLoader(),
      );
    }

    if (_allQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Word Bridge", centerTitle: true),
        body: Center(child: Text("No questions found", style: GoogleFonts.poppins())),
      );
    }

    final question = _allQuestions[_currentIndex];
    final currentOptions = question.options;
    final analogyText = question.questionText.split("::")[0].trim();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Word Bridge",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16), 
              child: Text(
                "Score: $_score", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
              )
            )
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             // Progress
             ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: LinearProgressIndicator(
                 value: (_currentIndex + 1) / _allQuestions.length,
                 backgroundColor: theme.dividerColor.withOpacity(0.1),
                 color: theme.colorScheme.primary,
                 minHeight: 8,
               ),
             ),
             const SizedBox(height: 40),
             
             // Bridge Visualization
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildStone(analogyText, isActive: true, theme: theme),
                 Expanded(
                   child: Divider(
                     thickness: 2, 
                     color: theme.dividerColor.withOpacity(0.2), 
                     indent: 10, 
                     endIndent: 10
                   )
                 ),
                 Icon(Icons.flag, color: theme.colorScheme.primary),
                 Expanded(
                   child: Divider(
                     thickness: 2, 
                     color: theme.dividerColor.withOpacity(0.2), 
                     indent: 10, 
                     endIndent: 10
                   )
                 ),
                 _buildStone("?", isActive: false, theme: theme), // Target
               ],
             ),
             
             const Spacer(),
             
             Text(
               "Current Analogy:",
               style: GoogleFonts.poppins(
                 color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
               ),
             ),
             const SizedBox(height: 8),
             Text(
               _currentWord,
               style: GoogleFonts.poppins(
                 fontSize: 28, 
                 fontWeight: FontWeight.bold, 
                 color: theme.colorScheme.primary
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 8),
             Icon(
               Icons.arrow_downward, 
               size: 32, 
               color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)
             ),
             const SizedBox(height: 8),
             Text(
               "Connects to...",
               style: GoogleFonts.poppins(
                 color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
               ),
             ),
             
             const Spacer(),
             
             // Options
             ...currentOptions.map((opt) {
                // Determine feedback color
                Color btnColor = theme.cardColor;
                Color textColor = theme.colorScheme.onSurface;
                
                if (_showFeedback) {
                   String correct = _allQuestions[_currentIndex].correctAnswer;
                   if (opt == correct) {
                     btnColor = Colors.green;
                     textColor = Colors.white;
                   } else if (opt == _selectedOption && !_lastChoiceCorrect) {
                     btnColor = Colors.red;
                     textColor = Colors.white;
                   }
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
                        foregroundColor: textColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1))
                      ),
                      child: Text(
                        opt, 
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                );
             }).toList(),
             const SizedBox(height: 8),
             TextButton(
               onPressed: _nextLevel,
               child: Text(
                 AppLocalizations.of(context)!.skip,
                 style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
               ),
             ),
             
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
            color: isActive ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isActive 
                ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                : [],
          ),
          child: Icon(
            isActive ? Icons.hub : Icons.place, 
            color: isActive ? Colors.white : theme.dividerColor
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text, 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color
          )
        )
      ],
    );
  }
}
