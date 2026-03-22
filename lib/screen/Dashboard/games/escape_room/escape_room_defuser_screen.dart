import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/utils/multiplayer_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class EscapeRoomDefuserScreen extends StatefulWidget {
  const EscapeRoomDefuserScreen({super.key});

  @override
  State<EscapeRoomDefuserScreen> createState() => _EscapeRoomDefuserScreenState();
}

class _EscapeRoomDefuserScreenState extends State<EscapeRoomDefuserScreen> {
  final MultiplayerService _service = MultiplayerService();
  EscapeGameState? _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = _service.activeRooms[_service.currentRoomId];
    
    _service.onStateChanged = (state) {
      if (!mounted) return;
      setState(() {
        _gameState = state;
      });
      
      if (state?.status == GameStatus.won || state?.status == GameStatus.lost) {
         _showEndGameDialog(state!);
      }
    };
  }
  
  void _showEndGameDialog(EscapeGameState state) {
      showDialog(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => AlertDialog(
            title: Text(state.status == GameStatus.won ? "Bomb Defused!" : "BOOM!"),
            content: Text(
               state.status == GameStatus.won 
               ? "Excellent teamwork. You survived with ${state.timeRemainingSeconds} seconds left!"
               : "You cut the wrong wire or ran out of time. Your team perished."
            ),
            actions: [
               OutlinedButton(
                  onPressed: () {
                     _service.leaveRoom();
                     Navigator.of(ctx).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Return to Dashboard"),
               )
            ],
         )
      );
  }

  Color _getColorFromName(String colorName) {
      switch(colorName) {
         case 'red': return Colors.red;
         case 'blue': return Colors.blue;
         case 'green': return Colors.green;
         case 'yellow': return Colors.yellow;
         case 'white': return Colors.white;
         case 'black': return Colors.black87;
         default: return Colors.grey;
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == null) return const CustomLoader();

    final theme = Theme.of(context);
    int mins = _gameState!.timeRemainingSeconds ~/ 60;
    int secs = _gameState!.timeRemainingSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
         backgroundColor: Colors.black,
         title: const Text("DEFUSER (PLAYER 1)", style: TextStyle(color: Colors.red)),
         automaticallyImplyLeading: false,
         actions: [
            TextButton(
               onPressed: () {
                  _service.leaveRoom();
                  Navigator.of(context).pop();
               },
               child: const Text("Skip", style: TextStyle(color: Colors.red)),
            )
         ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
               // Timer Module
               Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                     color: Colors.black,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.grey.shade800, width: 4),
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text(
                           "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}",
                           style: GoogleFonts.shareTechMono(fontSize: 48, color: Colors.red, fontWeight: FontWeight.bold)
                        ),
                        Column(
                           children: [
                              Text("STRIKES", style: GoogleFonts.shareTechMono(color: Colors.red, fontSize: 12)),
                              Row(
                                 children: List.generate(_gameState!.maxStrikes, (index) => Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                       Icons.close, 
                                       color: index < _gameState!.strikes ? Colors.red : Colors.grey.shade800,
                                    ),
                                 ))
                              )
                           ],
                        )
                     ],
                  ),
               ),
               const SizedBox(height: 32),
               
               // Readout Module (Serial)
               Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text("S/N", style: GoogleFonts.shareTechMono(color: Colors.grey.shade400)),
                        Text(
                           _gameState!.serialNumberIsOdd ? "AX-7391" : "AX-7392",
                           style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24, letterSpacing: 4)
                        ),
                     ],
                  ),
               ),
               const SizedBox(height: 32),
               
               // Wires Module
               Expanded(
                  child: Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade500, width: 8),
                     ),
                     child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_gameState!.wires.length, (index) {
                           bool isCut = _gameState!.wiresCut[index];
                           return GestureDetector(
                              onTap: () {
                                 if (!isCut && _gameState!.status == GameStatus.playing) {
                                     _service.cutWire(index);
                                 }
                              },
                              child: Row(
                                 children: [
                                    Container(width: 20, height: 20, color: Colors.grey.shade800),
                                    Expanded(
                                       child: Container(
                                          height: 16,
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                             color: _getColorFromName(_gameState!.wires[index]),
                                             border: Border.symmetric(horizontal: BorderSide(color: Colors.black.withOpacity(0.3))),
                                             gradient: isCut 
                                                ? null 
                                                : LinearGradient(
                                                   begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                                   colors: [
                                                      _getColorFromName(_gameState!.wires[index]).withOpacity(0.8),
                                                      _getColorFromName(_gameState!.wires[index]),
                                                      _getColorFromName(_gameState!.wires[index]).withOpacity(0.5),
                                                   ]
                                                )
                                          ),
                                          child: isCut 
                                             ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                   Container(width: 40, color: Colors.transparent), // Gap to show cut
                                                ]
                                             )
                                             : null,
                                       ),
                                    ),
                                    Container(width: 20, height: 20, color: Colors.grey.shade800),
                                 ],
                              ),
                           );
                        }),
                     ),
                  )
               ),
               
               const SizedBox(height: 24),
               Text(
                  "Describe what you see to the Expert. Only they have the manual to defuse this.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey),
               )
            ],
         ),
        ),
      )
    );
  }
}
