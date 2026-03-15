import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class WordChainScreen extends StatefulWidget {
  const WordChainScreen({super.key});

  @override
  State<WordChainScreen> createState() => _WordChainScreenState();
}

class _WordChainScreenState extends State<WordChainScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _gameOver = false;
  
  List<String> _chain = [];
  String _currentWord = "";

  List<String> _dictionary = [];
  
  final Random _random = Random();
  late TextEditingController _textController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _gameService.startSession(context);
    _fetchDynamicDictionary(); // Fetch new words
  }

  Future<void> _fetchDynamicDictionary() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getGameQuestions('Word Chain');
      print("Word Chain API Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Word Chain Data received: ${data.length} items");
        if (data.isNotEmpty) {
          Set<String> newWords = {};
          for (var item in data) {
            if (item['meta'] != null && item['meta']['wordsList'] != null) {
              String wordsStr = item['meta']['wordsList'];
              List<String> words = wordsStr.split(',').map((w) => w.trim().toUpperCase()).where((w) => w.isNotEmpty).toList();
              newWords.addAll(words);
            }
          }
          print("Word Chain Dictionary size: ${newWords.length}");
          if (newWords.isNotEmpty) {
            setState(() {
              _dictionary = newWords.toList();
            });
          }
        }
      } else {
        print("Word Chain Fetch failed: ${response.body}");
        // Fallback to minimal dictionary if empty to prevent crash
        if (_dictionary.isEmpty) {
          _dictionary = ["APPLE", "ELEPHANT", "TIGER", "RABBIT", "TRAIN"];
        }
      }
    } catch (e) {
      debugPrint("Error fetching word chain dictionary: $e");
    } finally {
      setState(() => _isLoading = false);
      _startRound(); // Start game after fetch
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    String startWord = _dictionary[_random.nextInt(_dictionary.length)];
    setState(() {
      _gameOver = false;
      _timeLeft = 60;
      _score = 0;
      _chain = [startWord];
      _textController.clear();
      _currentWord = startWord;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _gameOver = true;
        });
      }
    });
  }

  void _submitWord() {
    if (_gameOver) return;
    
    String input = _textController.text.trim().toUpperCase();
    if (input.isEmpty) return;

    String lastChar = _currentWord[_currentWord.length - 1];
    
    if (input.startsWith(lastChar) && _dictionary.contains(input) && !_chain.contains(input)) {
        setState(() {
            _chain.insert(0, input);
            _currentWord = input;
            _score += 10;
            _timeLeft += 3; // Bonus time
            _textController.clear();
        });
    } else {
        // Invalid word, wrong starting letter, or already used
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
               !input.startsWith(lastChar) ? "Must start with '$lastChar'!" : 
               _chain.contains(input) ? "Already used that word!" :
               "Not in dictionary!", 
               style: GoogleFonts.poppins()
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 800),
          )
        );
        setState(() {
            _timeLeft = max(0, _timeLeft - 2);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Word Chain", centerTitle: true),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoBadge(Icons.timer, "$_timeLeft s", _timeLeft < 10 ? Colors.red : theme.colorScheme.primary),
                    _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (_gameOver)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.link_off, size: 80, color: Colors.orange),
                         const SizedBox(height: 16),
                         Text("Time's Up!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                         const SizedBox(height: 8),
                         Text("Chain Length: ${_chain.length}", style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey)),
                         const SizedBox(height: 16),
                         Text("Final Score: $_score", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
                         const SizedBox(height: 32),
                         ElevatedButton(
                           onPressed: _startRound,
                           style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                             backgroundColor: theme.colorScheme.primary,
                             foregroundColor: theme.colorScheme.onPrimary,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                           ),
                           child: Text("Play Again", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                         )
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        Text("Enter a word starting with:", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.primary, width: 2)
                            ),
                            child: Text(
                                _currentWord.isEmpty ? "?" : _currentWord[_currentWord.length - 1], 
                                style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                        ),
                        const SizedBox(height: 32),
                        
                        TextField(
                          controller: _textController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: "Next Word",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _submitWord,
                            )
                          ),
                          onSubmitted: (_) => _submitWord(),
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text("Chain History", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Expanded(
                            child: ListView.builder(
                                itemCount: _chain.length,
                                itemBuilder: (context, index) {
                                    // First item currently at index 0 is most recent word
                                    bool isNewest = index == 0;
                                    return ListTile(
                                        leading: CircleAvatar(
                                            backgroundColor: isNewest ? theme.colorScheme.primary : theme.cardColor,
                                            child: Text("${_chain.length - index}", style: TextStyle(color: isNewest ? Colors.white : theme.colorScheme.onSurface)),
                                        ),
                                        title: Text(
                                            _chain[index],
                                            style: GoogleFonts.poppins(
                                                fontSize: 20, 
                                                fontWeight: isNewest ? FontWeight.bold : FontWeight.w500,
                                                color: isNewest ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                                            )
                                        ),
                                    );
                                }
                            )
                        )
                      ],
                    ),
                  ),
              ],
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

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
