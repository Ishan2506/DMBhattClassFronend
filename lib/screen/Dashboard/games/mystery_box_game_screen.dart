import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class MysteryBoxGameScreen extends StatefulWidget {
  const MysteryBoxGameScreen({super.key});

  @override
  State<MysteryBoxGameScreen> createState() => _MysteryBoxGameScreenState();
}

class _MysteryBoxGameScreenState extends State<MysteryBoxGameScreen> {
  bool _isLoading = true;
  String? _std;
  String? _selectedSubject;
  
  // Game State
  final List<int> _openeBoxes = [];
  Map<int, Map<String, dynamic>> _boxQuestions = {}; // Index -> Question Data

  // Colors from the screenshot (Red, Purple, Green, Orange, Blue)
  final List<Color> _boxColors = [
    const Color(0xFFC0392B), // Red
    const Color(0xFF8E44AD), // Purple
    const Color(0xFF27AE60), // Green
    const Color(0xFFD35400), // Orange
    const Color(0xFF2980B9), // Blue
  ];

  final List<String> _subjects = ["Maths", "Science", "English", "History", "Geography"];

  @override
  void initState() {
    super.initState();
    _fetchStandard();
  }

  Future<void> _fetchStandard() async {
    try {
      // Token managed internally
      final response = await ApiService.getProfile();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final profile = data['profile'];
          if (profile != null && profile['std'] != null) {
            setState(() {
              _std = profile['std'].toString();
            });
          }
        }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateQuestionsForSubject(String subject) {
    // Generate 15 questions for the boxes
    final random = Random();
    Map<int, Map<String, dynamic>> questions = {};

    for (int i = 0; i < 15; i++) {
        String qText = "";
        String answer = "";
        List<String> options = [];

        if (subject == "Maths") {
             int a = random.nextInt(20) + 1;
             int b = random.nextInt(20) + 1;
             if (i % 2 == 0) {
                qText = "$a + $b = ?";
                answer = "${a + b}";
                options = ["${a+b}", "${a+b+1}", "${a+b-1}", "${a+b+2}"]; 
             } else {
                qText = "$a * $b = ?";
                answer = "${a * b}";
                 options = ["${a*b}", "${a*b+2}", "${a*b-5}", "${a*b+10}"]; 
             }
        } else if (subject == "Science") {
           qText = "Question about $subject topic ${i+1}?";
           answer = "Correct Answer";
           options = ["Correct Answer", "Wrong 1", "Wrong 2", "Wrong 3"];
           
           // Simulated simple science DB
           List<Map<String, dynamic>> sciQs = [
             {"q": "What is H2O?", "a": "Water", "o": ["Water", "Air", "Fire", "Earth"]},
             {"q": "Center of atom?", "a": "Nucleus", "o": ["Nucleus", "Electron", "Proton", "Shell"]},
             {"q": "Force unit?", "a": "Newton", "o": ["Newton", "Joule", "Watt", "Pascal"]},
             {"q": "Powerhouse of cell?", "a": "Mitochondria", "o": ["Mitochondria", "Nucleus", "Ribosome", "Lysosome"]},
             {"q": "Speed of light?", "a": "3x10^8 m/s", "o": ["3x10^8 m/s", "300 km/h", "Sound speed", "Infinite"]}
           ];
           if (i < sciQs.length) {
              qText = sciQs[i]['q'];
              answer = sciQs[i]['a'];
              options = sciQs[i]['o'] as List<String>;
           }
        } else {
           // Generic
           qText = "$subject Question ${i+1}";
           answer = "Answer A";
           options = ["Answer A", "Answer B", "Answer C", "Answer D"];
        }

        options.shuffle();

        questions[i] = {
          "question": qText,
          "answer": answer,
          "options": options,
          "points": (i + 1) * 10 
        };
    }

    setState(() {
      _boxQuestions = questions;
      _selectedSubject = subject;
      _openeBoxes.clear();
    });
  }

  void _onBoxTap(int index) {
    if (_openeBoxes.contains(index)) return; // Already opened

    // Show Question Dialog
    final qData = _boxQuestions[index];
    if (qData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuestionDialog(
        question: qData['question'],
        options: qData['options'],
        correctAnswer: qData['answer'],
        points: qData['points'],
        onCorrect: () {
           setState(() {
             _openeBoxes.add(index);
           });
           Navigator.pop(context);
           _showRewardAnimation(qData['points']);
        },
        onWrong: () {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Wrong answer! Try again."), backgroundColor: Colors.red)
           );
        },
      ),
    );
  }

  void _showRewardAnimation(int points) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Correct! You earned $points points!"), 
          backgroundColor: Colors.amber, 
          duration: const Duration(seconds: 1)
        )
     );
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
     return Scaffold(
       backgroundColor: theme.brightness == Brightness.dark ? theme.scaffoldBackgroundColor : const Color(0xFF3E2723), // Dark Brown Bookshelf BG or System Dark
       appBar: CustomAppBar(
         title: "Knowledge Box",
         centerTitle: true,
         actions: [
           IconButton(
             icon: const Icon(Icons.refresh, color: Colors.white),
             onPressed: () {
               setState(() {
                 _selectedSubject = null;
                 _openeBoxes.clear();
               });
             },
           )
         ],
       ),
       body: _isLoading 
        ? const CustomLoader()
        : _selectedSubject == null 
            ? _buildSubjectSelection()
            : _buildGameGrid(),
     );
  }

  Widget _buildSubjectSelection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Standard: ${_std ?? 'Loading...'}",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            "Select Subject",
            style: GoogleFonts.poppins(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () => _generateQuestionsForSubject(_subjects[index]),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _boxColors[index % _boxColors.length],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.book, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      _subjects[index],
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return Column(
      children: [
         Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text(
             "Tap a box to open!",
             style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
           ),
         ),
         Expanded(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0),
             child: GridView.builder(
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 3,
                 childAspectRatio: 1.0,
                 crossAxisSpacing: 12,
                 mainAxisSpacing: 12,
               ),
               itemCount: 15, // 15 Boxes
               itemBuilder: (context, index) {
                  final isOpened = _openeBoxes.contains(index);
                  final color = _boxColors[index % _boxColors.length];
                  
                  return GestureDetector(
                    onTap: () => _onBoxTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        // 3D Bevel Effect
                        gradient: isOpened 
                           ? null // No gradient if opened (disabled look)
                           : LinearGradient(
                              colors: [
                                color.withOpacity(0.9),
                                color,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                        color: isOpened ? Colors.black26 : color, 
                        boxShadow: isOpened 
                          ? [] 
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2), 
                              offset: const Offset(-2, -2),
                              blurRadius: 0
                            )
                          ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        )
                      ),
                      child: Center(
                        child: isOpened 
                          ? const Icon(Icons.check, color: Colors.white54, size: 40)
                          : Text(
                              "${index + 1}",
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black26,
                                    offset: Offset(2, 2),
                                    blurRadius: 2,
                                  )
                                ]
                              ),
                            ),
                      ),
                    ),
                  );
               },
             ),
           ),
         ),
      ],
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int points;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  const _QuestionDialog({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.points,
    required this.onCorrect,
    required this.onWrong,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      title: Text(
        "For ${widget.points} Points", 
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(
             widget.question,
             style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 24),
           ...widget.options.map((opt) => Padding(
             padding: const EdgeInsets.only(bottom: 12),
             child: SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: theme.colorScheme.primaryContainer,
                   foregroundColor: theme.colorScheme.onPrimaryContainer,
                   elevation: 0,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                 ),
                 onPressed: () {
                    if (opt == widget.correctAnswer) {
                      widget.onCorrect();
                    } else {
                      widget.onWrong();
                    }
                 },
                 child: Text(opt, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
               ),
             ),
           )).toList()
        ],
      ),
    );
  }
}
