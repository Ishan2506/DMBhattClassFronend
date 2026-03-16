import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'dart:convert';

class GKQuizScreen extends StatefulWidget {
  const GKQuizScreen({super.key});

  @override
  State<GKQuizScreen> createState() => _GKQuizScreenState();
}

class GKQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;

  GKQuestion(this.question, this.correctAnswer, this.options);
}

class _GKQuizScreenState extends State<GKQuizScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();

  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isGameOver = false;

  final List<GKQuestion> _allQuestions = [
    GKQuestion(
      "Who is known as the Father of the Nation in India?",
      "Mahatma Gandhi",
      ["Mahatma Gandhi", "Jawaharlal Nehru", "Subhas Chandra Bose", "B. R. Ambedkar"]
    ),
    GKQuestion(
      "Which is the longest river in the world?",
      "Nile",
      ["Nile", "Amazon", "Ganges", "Mississippi"]
    ),
    GKQuestion(
      "What is the capital city of Australia?",
      "Canberra",
      ["Canberra", "Sydney", "Melbourne", "Perth"]
    ),
    GKQuestion(
      "Which planet is known as the Red Planet?",
      "Mars",
      ["Mars", "Venus", "Jupiter", "Saturn"]
    ),
    GKQuestion(
      "Who wrote the Indian National Anthem?",
      "Rabindranath Tagore",
      ["Rabindranath Tagore", "Bankim Chandra Chatterjee", "Sarojini Naidu", "Sri Aurobindo"]
    ),
    GKQuestion(
      "Which is the largest continent by area?",
      "Asia",
      ["Asia", "Africa", "North America", "Europe"]
    ),
    GKQuestion(
      "What is the freezing point of water in Celsius?",
      "0°C",
      ["0°C", "100°C", "-10°C", "32°C"]
    ),
    GKQuestion(
      "Which gas do plants absorb from the atmosphere?",
      "Carbon Dioxide",
      ["Carbon Dioxide", "Oxygen", "Nitrogen", "Hydrogen"]
    ),
    GKQuestion(
      "How many layers are there in the Earth's atmosphere?",
      "5",
      ["5", "4", "6", "3"]
    ),
    GKQuestion(
      "Which ocean is the largest on Earth?",
      "Pacific Ocean",
      ["Pacific Ocean", "Atlantic Ocean", "Indian Ocean", "Arctic Ocean"]
    ),
  ];

  late List<GKQuestion> _sessionQuestions = [];
  List<GKQuestion> _backendQuestions = [];
  late List<String> _currentOptions = [];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchDynamicQuestions();
  }

  Future<void> _fetchDynamicQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getGameQuestions('GK Quiz');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<GKQuestion> fetched = [];
        for (var item in data) {
          try {
            String questionText = item['questionText'] ?? "";
            String correctAnswer = item['correctAnswer'] ?? "";
            List<String> options = List<String>.from(item['options'] ?? []);
            
            if (questionText.isNotEmpty && correctAnswer.isNotEmpty && options.isNotEmpty) {
              fetched.add(GKQuestion(questionText, correctAnswer, options));
            }
          } catch (e) {
            debugPrint("Error parsing GK question: $e");
          }
        }
        if (fetched.isNotEmpty) {
          setState(() {
            _backendQuestions = fetched;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching GK questions: $e");
    } finally {
      setState(() => _isLoading = false);
      _startSession();
    }
  }

  void _startSession() {
    setState(() {
      _sessionQuestions = _backendQuestions.isNotEmpty ? List.from(_backendQuestions) : List.from(_allQuestions);
      _sessionQuestions.shuffle();
      // Use a subset of 5 questions per session to keep it quick
      _sessionQuestions = _sessionQuestions.take(5).toList();
      _currentIndex = 0;
      _score = 0;
      _isGameOver = false;
      _loadQuestion();
    });
  }

  void _loadQuestion() {
    if (_currentIndex < _sessionQuestions.length) {
      _currentOptions = List.from(_sessionQuestions[_currentIndex].options)..shuffle();
      setState(() {});
    } else {
      setState(() {
        _isGameOver = true;
      });
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(String selectedAnswer) {
    if (selectedAnswer == _sessionQuestions[_currentIndex].correctAnswer) {
      setState(() {
        _score += 20;
        _currentIndex++;
        _loadQuestion();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! The correct answer was: ${_sessionQuestions[_currentIndex].correctAnswer}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    }
  }

  void _showWinDialog() {
    // Deprecated in favor of inline game over UI
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
              _buildInstructionRow(theme, "1", "Read the general knowledge question carefully."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Review the four possible options below."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap the correct answer to score points."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Try to get all 5 questions right in a row!"),
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
                      "Q: longest river in the world?",
                      style: GoogleFonts.poppins(fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Answer: Nile",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: Text("Let's Play!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    if (!_isGameOver && (_isLoading || _sessionQuestions.isEmpty)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final question = !_isGameOver && _currentIndex < _sessionQuestions.length ? _sessionQuestions[_currentIndex] : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "GK Quiz",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (!_isGameOver && question != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Score Board
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Question ${_currentIndex + 1}/${_sessionQuestions.length}",
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentIndex++;
                                  _loadQuestion();
                                });
                              },
                              icon: const Icon(Icons.skip_next, size: 16),
                              label: Text(
                                AppLocalizations.of(context)!.skip,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Score: $_score",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Question Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        question.question,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Options List
                    ..._currentOptions.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: () => _checkAnswer(option),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            backgroundColor: theme.cardColor,
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            elevation: 2,
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            if (_isGameOver)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Game Over", 
                          style: GoogleFonts.poppins(
                            fontSize: 36, 
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          )
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Final Score", 
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$_score", 
                          style: GoogleFonts.poppins(
                            fontSize: 64, 
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          )
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _startSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                            shadowColor: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          child: Text(
                            "Play Again", 
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_isLoading)
               Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
