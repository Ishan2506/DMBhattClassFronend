import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  final MindGameService _gameService = MindGameService();

  List<GameQuestion> _allQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    MindGameService().startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Odd One Out');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allQuestions = data.map((json) => GameQuestion.fromJson(json)).toList();
          _allQuestions.shuffle();
          _isLoading = false;
        });
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
    MindGameService().stopSession();
    super.dispose();
  }

  void _handleOption(String option) {
    if (_isAnswered) return;

    final question = _allQuestions[_currentIndex];
    String correctAnswer = question.correctAnswer;
    bool correct = (option == correctAnswer);

    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      _isCorrect = correct;
      if (correct) _score += 10;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _allQuestions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedOption = null;
        });
      } else {
        _showGameOver();
      }
    });
  }
  
  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Final Score: $_score", style: GoogleFonts.poppins()),
        actions: [
          ElevatedButton(
            onPressed: () {Navigator.pop(context); Navigator.pop(context);},
            child: const Text("Exit"),
          ),
           TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _currentIndex = 0;
                _isAnswered = false;
                _selectedOption = null;
                _allQuestions.shuffle();
              });
            },
            child: const Text("Play Again"),
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
        appBar: CustomAppBar(title: "Odd One Out", centerTitle: true),
        body: const CustomLoader(),
      );
    }

    if (_allQuestions.isEmpty) {
       return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Odd One Out", centerTitle: true),
        body: Center(child: Text("No questions available", style: GoogleFonts.poppins())),
      );
    }

    final question = _allQuestions[_currentIndex];
    final List<String> options = question.options;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Odd One Out",
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _allQuestions.length,
                color: theme.colorScheme.primary,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              question.questionText.isNotEmpty ? question.questionText : "Which one does not belong?",
              style: GoogleFonts.poppins(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.titleLarge?.color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                   final opt = options[index];
                   Color bg = theme.cardColor;
                   Color border = theme.dividerColor.withOpacity(0.2);
                   Color text = theme.colorScheme.onSurface;
                   
                   if (_isAnswered) {
                     if (opt == question.correctAnswer) {
                       bg = Colors.green;
                       text = Colors.white;
                       border = Colors.green;
                     } else if (opt == _selectedOption) {
                       bg = Colors.red;
                       text = Colors.white;
                       border = Colors.red;
                     } else {
                       bg = theme.disabledColor.withOpacity(0.1);
                       text = theme.disabledColor;
                     }
                   }

                   return GestureDetector(
                     onTap: () => _handleOption(opt),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 300),
                       decoration: BoxDecoration(
                         color: bg,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: border, width: 2),
                         boxShadow: [
                           if (!_isAnswered) 
                             BoxShadow(
                               color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                               blurRadius: 4, 
                               offset: const Offset(0, 4)
                             )
                         ]
                       ),
                       child: Center(
                         child: Text(
                           opt,
                           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ),
                   );
                },
              ),
            ),
            
            if (_isAnswered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isCorrect ? Colors.green : Colors.red)
                ),
                child: Column(
                  children: [
                    Text(
                      _isCorrect ? "Correct!" : "Wrong!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _isCorrect ? Colors.green : Colors.red, 
                        fontWeight: FontWeight.bold,
                        fontSize: 18
                      ),
                    ),
                    if (question.meta.containsKey('reason')) ...[
                      const SizedBox(height: 8),
                      Text(
                        question.meta['reason'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 14
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
