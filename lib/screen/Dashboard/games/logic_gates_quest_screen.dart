import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

enum GateType { and, or, xor, not }

class LogicQuestion {
  final bool input1;
  final bool? input2; // null for NOT gate
  final GateType gate;
  final bool answer;

  const LogicQuestion(this.input1, this.input2, this.gate, this.answer);
}

class LogicGatesQuestScreen extends StatefulWidget {
  const LogicGatesQuestScreen({super.key});

  @override
  State<LogicGatesQuestScreen> createState() => _LogicGatesQuestScreenState();
}

class _LogicGatesQuestScreenState extends State<LogicGatesQuestScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  LogicQuestion? _currentQuestion;
  List<LogicQuestion> _backendQuestions = [];
  List<int> _usedBackendIndices = [];
  bool _isLoading = true;
  int _score = 0;
  int _timeLeft = 45;
  Timer? _timer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchDynamicQuestions();
  }

  Future<void> _fetchDynamicQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getGameQuestions('Logic Gates Quest');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<LogicQuestion> fetched = [];
        for (var item in data) {
          try {
            String text = item['questionText'] ?? "";
            // Parse "1 AND 0 = ?" or similar
            final parts = text.split(' ');
            if (parts.length >= 3) {
              bool in1 = parts[0] == "1";
              String gateStr = parts[1].toLowerCase();
              GateType gate;
              bool? in2;
              
              if (gateStr == "not") {
                gate = GateType.not;
                in2 = null;
              } else {
                in2 = parts[2] == "1";
                if (gateStr == "and") gate = GateType.and;
                else if (gateStr == "or") gate = GateType.or;
                else if (gateStr == "xor") gate = GateType.xor;
                else continue;
              }
              
              bool ans = (item['correctAnswer'] == "1" || item['correctAnswer'].toString().toLowerCase() == "true");
              fetched.add(LogicQuestion(in1, in2, gate, ans));
            }
          } catch (e) {
            debugPrint("Error parsing logic question: $e");
          }
        }
        if (fetched.isNotEmpty) {
          setState(() {
            _backendQuestions = fetched;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching logic gates questions: $e");
    } finally {
      setState(() => _isLoading = false);
      _startGame();
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 45;
      _isGameOver = false;
      _usedBackendIndices = [];
    });
    _generateQuestion();
    _startTimer();
  }

  void _generateQuestion() {
    if (_backendQuestions.isNotEmpty) {
      if (_usedBackendIndices.length >= _backendQuestions.length) {
        setState(() {
          _isGameOver = true;
        });
        _timer?.cancel();
        return;
      }

      int nextIndex;
      do {
        nextIndex = _random.nextInt(_backendQuestions.length);
      } while (_usedBackendIndices.contains(nextIndex));

      setState(() {
        _usedBackendIndices.add(nextIndex);
        _currentQuestion = _backendQuestions[nextIndex];
      });
      return;
    }

    // Fallback to random generation
    final gate = GateType.values[_random.nextInt(GateType.values.length)];
    final in1 = _random.nextBool();
    bool? in2;
    bool ans;

    switch (gate) {
      case GateType.and:
        in2 = _random.nextBool();
        ans = in1 && in2;
        break;
      case GateType.or:
        in2 = _random.nextBool();
        ans = in1 || in2;
        break;
      case GateType.xor:
        in2 = _random.nextBool();
        ans = in1 ^ in2;
        break;
      case GateType.not:
        in2 = null;
        ans = !in1;
        break;
    }

    setState(() {
      _currentQuestion = LogicQuestion(in1, in2, gate, ans);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        setState(() => _isGameOver = true);
        _timer?.cancel();
      }
    });
  }

  void _checkAnswer(bool selected) {
    if (_isGameOver || _currentQuestion == null) return;

    if (selected == _currentQuestion!.answer) {
      setState(() {
        _score += 10;
        _timeLeft += 2;
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correct!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 300)),
      );
    } else {
      setState(() {
        _timeLeft = max(0, _timeLeft - 5);
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong! -5s"), backgroundColor: Colors.red, duration: Duration(milliseconds: 300)),
      );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.help_outline_rounded, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "How to Play",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", "Observe the input values (1 for True, 0 for False)."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Apply the logic gate (AND, OR, XOR, NOT) to the inputs."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap the correct result: TRUE (1) or FALSE (0)."),
              const SizedBox(height: 24),
              
              // Example Box: AND Gate
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text("Example: AND Gate", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.tertiary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniValue(true),
                        const SizedBox(width: 8),
                        const Text("AND", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _buildMiniValue(false),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                        const SizedBox(width: 8),
                        _buildMiniValue(false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Result is 1 only if BOTH are 1.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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
                ),
                child: Text("Got it!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniValue(bool val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: val ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: val ? Colors.green : Colors.red),
      ),
      child: Text(val ? "1" : "0", style: TextStyle(fontWeight: FontWeight.bold, color: val ? Colors.green : Colors.red)),
    );
  }

  Widget _buildInstructionRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.logicGatesQuest,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),

      body: Stack(
        children: [
          if (!_isGameOver && _currentQuestion != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBadge("Score: $_score", Icons.star, Colors.amber),
                      _buildStatBadge("Time: $_timeLeft s", Icons.timer, _timeLeft < 10 ? Colors.red : Colors.blue),
                    ],
                  ),
                  const Spacer(),
                  
                  // Logic Diagram
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildValueBox(_currentQuestion!.input1, theme),
                            if (_currentQuestion!.input2 != null) ...[
                              const SizedBox(width: 16),
                              _buildValueBox(_currentQuestion!.input2!, theme),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary),
                          ),
                          child: Text(
                            _currentQuestion!.gate.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Icon(Icons.arrow_downward_rounded, size: 40, color: Colors.grey),
                        const SizedBox(height: 16),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2), width: 2),
                          ),
                          child: const Center(
                            child: Text("?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Answer Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnswerButton(true, Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnswerButton(false, Colors.red),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          
          if (_isGameOver)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
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
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          "Restart Game", 
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
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildValueBox(bool value, ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: value ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? Colors.green : Colors.red, width: 2),
      ),
      child: Center(
        child: Text(
          value ? "1" : "0",
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: value ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(bool value, Color color) {
    return ElevatedButton(
      onPressed: () => _checkAnswer(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Text(
        value ? "TRUE (1)" : "FALSE (0)",
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
