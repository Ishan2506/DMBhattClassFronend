import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class SortingSweepScreen extends StatefulWidget {
  const SortingSweepScreen({super.key});

  @override
  State<SortingSweepScreen> createState() => _SortingSweepScreenState();
}

class _SortingSweepScreenState extends State<SortingSweepScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 45;
  Timer? _timer;
  bool _gameOver = false;
  
  List<_SortableItem> _items = [];
  int _expectedNextSequenceIndex = 0;
  List<int> _sortedValues = [];

  final Random _random = Random();
  
  double _boxWidth = 300.0;
  double _boxHeight = 400.0;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRound();
    });
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _gameOver = false;
      _timeLeft = 45; // Fixed 45 second round. Goal is to do as many boards as possible
      _generateBoard();
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
  
  void _generateBoard() {
      _items.clear();
      _sortedValues.clear();
      _expectedNextSequenceIndex = 0;
      
      int numItems = _random.nextInt(4) + 6; // 6 to 9 items
      
      // Make it slightly mathematical, e.g evaluated expressions or just numbers
      for (int i = 0; i < numItems; i++) {
          int value;
          String display;
          
          int type = _random.nextInt(3);
          if (type == 0) {
              // Just a number
              value = _random.nextInt(100);
              display = "$value";
          } else if (type == 1) {
              // Addition
              int a = _random.nextInt(30);
              int b = _random.nextInt(30);
              value = a + b;
              display = "$a + $b";
          } else {
              // Multiplication
              int a = _random.nextInt(10) + 2;
              int b = _random.nextInt(10) + 2;
              value = a * b;
              display = "$a x $b";
          }
          
          // Ensure uniqueness of values for strict ascending check
          while (_sortedValues.contains(value)) {
              value++;
              // Just make it a raw number to fix collision safely
              display = "$value";
          }
          
          _sortedValues.add(value);
          
          // Random coordinates within bounding box considering item size
          double padding = 30.0; // Assume 60x60 item
          _items.add(_SortableItem(
              id: i,
              display: display, 
              value: value,
              x: padding + _random.nextDouble() * (_boxWidth - padding * 2),
              y: padding + _random.nextDouble() * (_boxHeight - padding * 2),
          ));
      }
      
      _sortedValues.sort();
  }

  void _onItemTap(_SortableItem item) {
    if (_gameOver || item.tapped) return;

    if (item.value == _sortedValues[_expectedNextSequenceIndex]) {
        // Correct order!
        setState(() {
            _items.firstWhere((element) => element.id == item.id).tapped = true;
            _expectedNextSequenceIndex++;
            _score += 10;
        });
        
        // Did we finish the board?
        if (_expectedNextSequenceIndex == _sortedValues.length) {
            _score += 50; // Board clear bonus
            Future.delayed(const Duration(milliseconds: 300), () {
                if (!_gameOver) {
                    setState(() {
                        _generateBoard();
                    });
                }
            });
        }
    } else {
        // Wrong order! Penalty!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
               "Wrong! Next lowest is ${_sortedValues[_expectedNextSequenceIndex]}.", 
               style: GoogleFonts.poppins()
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 700),
          )
        );
        setState(() {
           _timeLeft = max(0, _timeLeft - 3);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Sorting Sweep", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.timer, "$_timeLeft s", _timeLeft < 10 ? Colors.red : theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _generateBoard();
                    });
                  },
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: Text(
                    AppLocalizations.of(context)!.skip,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("Tap the floating values in strictly ascending order (lowest to highest). Clear as many boards as possible!", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),

            if (_gameOver)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.sort, size: 80, color: theme.colorScheme.primary),
                     const SizedBox(height: 16),
                     Text("Time's Up!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
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
                child: Center(
                    child: LayoutBuilder(
                        builder: (context, constraints) {
                            // Update internal box size once layout available if needed, though we set it abstractly.
                            // We will scale down if the screen is tiny, otherwise hold the abstract width/height
                            _boxWidth = min(constraints.maxWidth, 350.0);
                            _boxHeight = min(constraints.maxHeight, 500.0);
                            
                            return Container(
                                width: _boxWidth,
                                height: _boxHeight,
                                decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    border: Border.all(color: theme.dividerColor, width: 2),
                                    borderRadius: BorderRadius.circular(16)
                                ),
                                child: Stack(
                                    children: _items.map((item) {
                                        return Positioned(
                                            left: min(max(0, item.x - 30), _boxWidth - 60),
                                            top: min(max(0, item.y - 30), _boxHeight - 60),
                                            child: GestureDetector(
                                                onTap: () => _onItemTap(item),
                                                child: AnimatedScale(
                                                    scale: item.tapped ? 0.0 : 1.0,
                                                    duration: const Duration(milliseconds: 300),
                                                    child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        decoration: BoxDecoration(
                                                            color: theme.cardColor,
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: theme.colorScheme.primary),
                                                            boxShadow: [
                                                                BoxShadow(color: Colors.black26, offset: const Offset(0, 2), blurRadius: 4)
                                                            ]
                                                        ),
                                                        child: Center(
                                                            child: Text(
                                                                item.display,
                                                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        );
                                    }).toList(),
                                )
                            );
                        }
                    )
                ),
              ),
          ],
        ),
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

class _SortableItem {
    final int id;
    final String display;
    final int value;
    final double x;
    final double y;
    bool tapped;
    
    _SortableItem({
        required this.id,
        required this.display,
        required this.value,
        required this.x,
        required this.y,
        this.tapped = false
    });
}
