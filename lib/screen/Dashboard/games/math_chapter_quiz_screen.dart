import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class MathChapterQuizScreen extends StatefulWidget {
  const MathChapterQuizScreen({super.key});

  @override
  State<MathChapterQuizScreen> createState() => _MathChapterQuizScreenState();
}

class _MathChapterQuizScreenState extends State<MathChapterQuizScreen> {
  bool _isLoading = true;
  String? _std;
  String? _selectedChapter;
  int _score = 0;
  int _currentQuestionIndex = 0;
  bool _isGameOver = false;
  
  // Data
  final Map<String, List<String>> _chaptersByStd = {
    "6": ["Numbers", "Fractions"],
    "7": ["Integers", "Simple Equations"],
    "8": ["Rational Numbers", "Linear Equations"],
    "9": ["Number Systems", "Polynomials"],
    "10": ["Real Numbers", "Polynomials", "Quadratics"],
    "11": ["Sets", "Relations & Functions", "Trigonometry"],
    "12": ["Relations & Functions", "Matrices", "Calculus"],
  };

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchStandard();
  }

  Future<void> _fetchStandard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final response = await ApiService.getProfile(token);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final profile = data['profile'];
          if (profile != null && profile['std'] != null) {
            setState(() {
              _std = profile['std'].toString();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startQuiz(String chapter) {
    setState(() {
      _selectedChapter = chapter;
      _score = 0;
      _currentQuestionIndex = 0;
      _isGameOver = false;
      _questions = _generateQuestions(_std!, chapter);
    });
  }

  List<Map<String, dynamic>> _generateQuestions(String std, String chapter) {
    // This is a simplified generator. In a real app, you might fetch these or have a larger local DB.
    List<Map<String, dynamic>> q = [];
    final random = Random();

    for (int i = 0; i < 5; i++) { // Generate 5 questions per session
       int a = random.nextInt(20) + 1;
       int b = random.nextInt(20) + 1;
       int ans = 0;
       String questionText = "";
       List<String> options = [];

       String correctStr = "";

       // Simple logic to vary content by "Chapter" (conceptually)
       if (chapter.contains("Polynomials") || chapter.contains("Equations")) {
           // Algebra: Find x if x + a = b
           ans = b - a;
           questionText = "Solve for x: x + $a = $b";
           options = [
             "$ans", 
             "${ans + 1}", 
             "${ans - 1}", 
             "${ans + 2}"
           ];
           correctStr = "$ans";
       } else if (chapter.contains("Trigonometry")) {
           // Basic Trig identities or values (Simulated)
           final angles = [0, 30, 45, 60, 90];
           final angle = angles[random.nextInt(angles.length)];
           questionText = "What is sin($angle°)?";
           if (angle == 0) ans = 0; // Simplified for int check, ideally these are doubles/strings
           options = ["0", "0.5", "1", "√3/2"]; 
           // Fix specific correct answer for the string check
           if (angle == 30) options = ["0.5", "1", "0", "√3/2"];
           if (angle == 45) options = ["1/√2", "1", "0.5", "0"];
           if (angle == 60) options = ["√3/2", "0.5", "1", "0"];
           if (angle == 90) options = ["1", "0", "0.5", "√3/2"];
           if (angle == 0) options = ["0", "1", "0.5", "√3/2"];

           if (angle == 0) correctStr = "0";
           if (angle == 30) correctStr = "0.5";
           if (angle == 45) correctStr = "1/√2";
           if (angle == 60) correctStr = "√3/2";
           if (angle == 90) correctStr = "1";

       } else if (chapter.contains("Calculus")) {
           // Derivative of x^n
           int n = random.nextInt(5) + 2;
           questionText = "d/dx (x^$n)";
           options = [
             "$n x^${n-1}", 
             "$n x^${n+1}", 
             "x^${n-1}", 
             "${n-1} x^$n"
           ];
           correctStr = "$n x^${n-1}";
       } else {
           // Default Arithmetic
           ans = a + b;
           questionText = "$a + $b = ?";
           options = ["$ans", "${ans+1}", "${ans-1}", "${ans+2}"];
           correctStr = "$ans";
       }

       options.shuffle();

       q.add({
         "question": questionText,
         "options": options,
         "answer": correctStr
       });
    }
    return q;
  }

  void _checkAnswer(String selected) {
    if (_questions[_currentQuestionIndex]['answer'] == selected) {
      setState(() {
        _score += 10;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correct!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 500))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! Answer: ${_questions[_currentQuestionIndex]['answer']}"), 
          backgroundColor: Colors.red, duration: const Duration(seconds: 1)
        )
      );
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _isGameOver = true;
      });
    }
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
             Text("1. Select a chapter based on your standard.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Answer the generated questions.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Questions increase in difficulty.", style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: CustomAppBar(
        title: "Subject Quiz",
        centerTitle: true,
        actions: [
             IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _selectedChapter == null 
              ? _buildChapterSelection() 
              : _buildQuiz(),
    );
  }

  Widget _buildChapterSelection() {
    List<String> chapters = _chaptersByStd[_std] ?? ["General Math", "Logic"];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Standard: $_std",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Text(
            "Select Chapter:",
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.book, color: Colors.indigo),
                    ),
                    title: Text(chapters[index], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _startQuiz(chapters[index]),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    if (_isGameOver) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Quiz Completed!", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 16),
            Text("Score: $_score / 50", style: GoogleFonts.poppins(fontSize: 24)),
            const SizedBox(height: 32),
             ElevatedButton(
               onPressed: () {
                 setState(() {
                   _selectedChapter = null; // Back to selection
                 });
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.indigo,
                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
               ),
               child: Text("Back to Chapters", style: GoogleFonts.poppins(color: Colors.white)),
             )
          ],
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Chapter: $_selectedChapter", style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.w500)),
              Text("Q: ${_currentQuestionIndex + 1}/5", style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Text(
            question['question'], 
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ...List.generate(question['options'].length, (index) {
             return Padding(
               padding: const EdgeInsets.only(bottom: 16.0),
               child: SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   onPressed: () => _checkAnswer(question['options'][index]),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.indigo,
                     elevation: 2,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     side: BorderSide(color: Colors.indigo.shade100)
                   ),
                   child: Text(
                     question['options'][index],
                     style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                   ),
                 ),
               ),
             );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}
