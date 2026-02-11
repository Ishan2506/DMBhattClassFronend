import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class ChronologyChallengeScreen extends StatefulWidget {
  const ChronologyChallengeScreen({super.key});

  @override
  State<ChronologyChallengeScreen> createState() => _ChronologyChallengeScreenState();
}

class _ChronologyChallengeScreenState extends State<ChronologyChallengeScreen> {
  final MindGameService _gameService = MindGameService();
  // Data Structure: Category -> List of Events
  final Map<String, List<Map<String, dynamic>>> _allLevels = {
    "Inventions": [
      {"event": "Wheel Invented", "year": -3500},
      {"event": "Printing Press", "year": 1440},
      {"event": "Light Bulb", "year": 1879},
      {"event": "Airplane", "year": 1903},
      {"event": "Internet", "year": 1983},
    ],
    "Indian History": [
      {"event": "Indus Valley Civilization", "year": -2500},
      {"event": "Maurya Empire", "year": -322},
      {"event": "Gupta Empire", "year": 320},
      {"event": "Mughal Empire", "year": 1526},
      {"event": "Independence", "year": 1947},
    ],
    "Science Discoveries": [
      {"event": "Gravity (Newton)", "year": 1687},
      {"event": "Oxygen Discovered", "year": 1774},
      {"event": "Theory of Relativity", "year": 1905},
      {"event": "DNA Structure", "year": 1953},
      {"event": "Higgs Boson", "year": 2012},
    ],
  };

  String? _selectedCategory;
  List<Map<String, dynamic>> _currentEvents = [];
  bool _isChecked = false;
  bool _isCorrect = false;
  int _hintsRemaining = 2; // Hints per level

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startLevel(String category) {
    List<Map<String, dynamic>> events = List.from(_allLevels[category]!);
    events.shuffle(); // Shuffle for the game
    setState(() {
      _selectedCategory = category;
      _currentEvents = events;
      _isChecked = false;
      _isCorrect = false;
      _hintsRemaining = 2;
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0) return;
    
    // Find the earliest date in the current list
    // Check if it's already at index 0
    // If not, swap it to index 0 and lock it visually (optional, but for now just move it)
    
    // Simple hint: Identify the oldest event
    final sortedEvents = List<Map<String, dynamic>>.from(_currentEvents);
    sortedEvents.sort((a, b) => a['year'].compareTo(b['year']));
    final oldest = sortedEvents.first;
    
    setState(() {
      _hintsRemaining--;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hint"),
        content: Text("The oldest event here is:\n\n'${oldest['event']}'\n\nIt should be at the top!"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _checkOrder() {
    bool correct = true;
    for (int i = 0; i < _currentEvents.length - 1; i++) {
        if (_currentEvents[i]['year'] > _currentEvents[i+1]['year']) {
          correct = false;
          break;
        }
    }

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
    });

    if (correct) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect Order! Try again."), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Correct!"),
        content: const Text("You have arranged the timeline correctly!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _selectedCategory = null; // Back to menu
              });
            },
            child: const Text("Choose Another Topic"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Chronology Challenge",
        centerTitle: true,
        actions: [
          if (_selectedCategory != null)
             IconButton(
               icon: Badge(
                 label: Text("$_hintsRemaining"),
                 isLabelVisible: _hintsRemaining > 0,
                 child: const Icon(Icons.lightbulb, color: Colors.amber),
               ),
               onPressed: _hintsRemaining > 0 ? _useHint : null,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
               if (_selectedCategory != null) _startLevel(_selectedCategory!);
            },
          )
        ],
      ),
      body: _selectedCategory == null 
        ? _buildCategorySelection(theme) 
        : _buildGameArea(theme),
    );
  }

  Widget _buildCategorySelection(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Select a Topic",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 20),
        ..._allLevels.keys.map((category) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ElevatedButton(
            onPressed: () => _startLevel(category),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(
              category,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildGameArea(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Drag and drop events from Oldest (Top) to Newest (Bottom)",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onReorder: (oldIndex, newIndex) {
               setState(() {
                 if (newIndex > oldIndex) newIndex -= 1;
                 final item = _currentEvents.removeAt(oldIndex);
                 _currentEvents.insert(newIndex, item);
                 _isChecked = false; // Reset check status on move
               });
            },
            children: [
              for (int i = 0; i < _currentEvents.length; i++)
                Card(
                  key: ValueKey(_currentEvents[i]['event']),
                  color: theme.cardColor,
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text("${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ),
                    title: Text(
                      _currentEvents[i]['event'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        fontSize: 16,
                        color: theme.colorScheme.onSurface
                      ),
                    ),
                    trailing: _isChecked 
                      ? Text(
                          "${_currentEvents[i]['year'] < 0 ? '${_currentEvents[i]['year'].abs()} BC' : _currentEvents[i]['year']}",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        )
                      : Icon(Icons.drag_handle, color: theme.dividerColor),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                blurRadius: 10, 
                offset: const Offset(0, -5)
              )
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _checkOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Check Order", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
