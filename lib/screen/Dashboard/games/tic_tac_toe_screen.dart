import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> _board = List.generate(9, (_) => "");
  String _currentPlayer = "X";
  String _winner = "";
  bool _isDraw = false;
  bool _vsComputer = true; // Default vs Computer

  void _resetGame() {
    setState(() {
      _board = List.generate(9, (_) => "");
      _currentPlayer = "X";
      _winner = "";
      _isDraw = false;
    });
  }

  void _onTileTap(int index) {
    if (_board[index] != "" || _winner != "") return;

    setState(() {
      _board[index] = _currentPlayer;
      if (_checkWinner(_currentPlayer)) {
        _winner = _currentPlayer;
      } else if (!_board.contains("")) {
        _isDraw = true;
      } else {
        _currentPlayer = _currentPlayer == "X" ? "O" : "X";
        if (_vsComputer && _currentPlayer == "O") {
          _computerMove();
        }
      }
    });
  }

  void _computerMove() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate thinking
    if (_winner != "" || _isDraw) return;

    // Simple AI: Random empty spot
    // TODO: Implement Minimax for harder difficulty
    int bestMove = -1;
    
    // 1. Try to win
    for (int i = 0; i < 9; i++) {
        if (_board[i] == "") {
            _board[i] = "O";
            if (_checkWinner("O")) {
                bestMove = i;
                _board[i] = ""; // backtrack
                break;
            }
            _board[i] = ""; // backtrack
        }
    }

    // 2. Block X from winning
    if (bestMove == -1) {
        for (int i = 0; i < 9; i++) {
            if (_board[i] == "") {
                _board[i] = "X";
                if (_checkWinner("X")) {
                    bestMove = i;
                    _board[i] = "";
                    break;
                }
                _board[i] = "";
            }
        }
    }

    // 3. Pick random
    if (bestMove == -1) {
        List<int> emptyIndices = [];
        for (int i = 0; i < 9; i++) {
          if (_board[i] == "") emptyIndices.add(i);
        }
        if (emptyIndices.isNotEmpty) {
           bestMove = emptyIndices[(DateTime.now().millisecond % emptyIndices.length)];
        }
    }

    if (bestMove != -1 && mounted) {
      setState(() {
        _board[bestMove] = "O";
        if (_checkWinner("O")) {
          _winner = "O";
        } else if (!_board.contains("")) {
          _isDraw = true;
        } else {
          _currentPlayer = "X";
        }
      });
    }
  }

  bool _checkWinner(String player) {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var w in wins) {
      if (_board[w[0]] == player &&
          _board[w[1]] == player &&
          _board[w[2]] == player) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Tic Tac Toe",
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           // Status
           Text(
             _winner != "" 
                 ? "Winner: $_winner" 
                 : (_isDraw ? "It's a Draw!" : "Turn: $_currentPlayer"),
             style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
           ),
           const SizedBox(height: 32),
           
           // Board
           Container(
             margin: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: theme.cardColor,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                   blurRadius: 10, 
                   offset: const Offset(0, 4)
                 )
               ]
             ),
             child: GridView.builder(
               shrinkWrap: true,
               padding: const EdgeInsets.all(16),
               physics: const NeverScrollableScrollPhysics(),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 3,
                 crossAxisSpacing: 8,
                 mainAxisSpacing: 8,
               ),
               itemCount: 9,
               itemBuilder: (context, index) {
                 return GestureDetector(
                   onTap: () => _onTileTap(index),
                   child: Container(
                     decoration: BoxDecoration(
                       color: theme.brightness == Brightness.dark 
                           ? theme.colorScheme.surfaceVariant.withOpacity(0.3) 
                           : theme.colorScheme.primary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Center(
                       child: Text(
                         _board[index],
                         style: GoogleFonts.fredoka(
                           fontSize: 48, 
                           fontWeight: FontWeight.bold,
                           color: _board[index] == "X" ? Colors.blue.shade700 : Colors.red.shade400
                         ),
                       ),
                     ),
                   ),
                 );
               },
             ),
           ),
           
           const SizedBox(height: 32),
           
           ElevatedButton.icon(
             onPressed: _resetGame, 
             icon: const Icon(Icons.refresh), 
             label: const Text("Restart Game"),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               backgroundColor: theme.colorScheme.primary,
               foregroundColor: Colors.white,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
           ),
        ],
      ),
    );
  }
}
