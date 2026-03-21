import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class CapitalCityQuestScreen extends StatefulWidget {
  const CapitalCityQuestScreen({super.key});

  @override
  State<CapitalCityQuestScreen> createState() => _CapitalCityQuestScreenState();
}

class GeographyFact {
  final String region;    // e.g. "Gujarat" or "France"
  final String capital;   // e.g. "Gandhinagar" or "Paris"
  final List<String> options;

  GeographyFact(this.region, this.capital, {this.options = const []});

  factory GeographyFact.fromGameQuestion(GameQuestion q) {
    return GeographyFact(
      q.questionText, 
      q.correctAnswer,
      options: q.options ?? [],
    );
  }
}

class _CapitalCityQuestScreenState extends State<CapitalCityQuestScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();

  int _currentIndex = 0;
  int _score = 0;
  List<String> _currentOptions = [];
  bool _isLoading = true;

  List<GeographyFact> _allFacts = [];
  late List<GeographyFact> _sessionFacts;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Capital City Quest');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allFacts = data.map((json) => GeographyFact.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          _isLoading = false;
          _startSession();
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching capital city questions: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startSession() {
    if (_allFacts.isEmpty) return;
    _sessionFacts = List.from(_allFacts)..shuffle();
    _currentIndex = 0;
    _score = 0;
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_sessionFacts.isEmpty) return;
    if (_currentIndex >= _sessionFacts.length) {
      _showWinDialog();
      return;
    }

    final currentFact = _sessionFacts[_currentIndex];
    
    if (currentFact.options.isNotEmpty) {
      _currentOptions = List.from(currentFact.options)..shuffle();
    } else {
      // Pick 3 random wrong options from all available capitals
      final allCapitals = _allFacts.map((f) => f.capital).toSet().toList();
      final wrongOptions = allCapitals
          .where((c) => c != currentFact.capital)
          .toList()
          ..shuffle();
          
      _currentOptions = [currentFact.capital];
      for (int i = 0; i < min(3, wrongOptions.length); i++) {
        _currentOptions.add(wrongOptions[i]);
      }
      _currentOptions.shuffle();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(String selectedCapital) {
    if (selectedCapital == _sessionFacts[_currentIndex].capital) {
      setState(() {
        _score += 10;
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
          content: Text("Wrong! It's ${_sessionFacts[_currentIndex].capital}."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Quest Complete!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You scored $_score out of ${_sessionFacts.length * 10} points.",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _startSession());
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit game
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
              _buildInstructionRow(theme, "1", "A Country or Indian State will be shown in the center."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Read the four city names provided below it."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap the correct Capital City for that region."),
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
                      "Example Idea",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "France",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
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
                        "Paris",
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_allFacts.isEmpty) {
       return Scaffold(
          appBar: const CustomAppBar(title: "Capital City Quest", centerTitle: true),
          body: Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.public_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text("No questions found.", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                ],
             ),
          ),
       );
    }

    if (_currentIndex >= _sessionFacts.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final fact = _sessionFacts[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Capital City Quest",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
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
                         "Quest ${_currentIndex + 1}/${_sessionFacts.length}",
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
              
              const Spacer(),
              
              const Icon(Icons.public, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 24),
              
              // Big State/Country Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      "What is the capital of",
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fact.region,
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.0,
                  children: _currentOptions.map((city) {
                    return ElevatedButton(
                      onPressed: () => _checkAnswer(city),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                      ),
                      child: Text(
                        city,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
