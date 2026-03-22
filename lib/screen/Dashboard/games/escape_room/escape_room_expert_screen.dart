import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/utils/multiplayer_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class EscapeRoomExpertScreen extends StatefulWidget {
  const EscapeRoomExpertScreen({super.key});

  @override
  State<EscapeRoomExpertScreen> createState() => _EscapeRoomExpertScreenState();
}

class _EscapeRoomExpertScreenState extends State<EscapeRoomExpertScreen> {
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
               : "The Defuser cut the wrong wire or ran out of time. Your team perished."
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

  @override
  Widget build(BuildContext context) {
    if (_gameState == null) return const CustomLoader();

    int mins = _gameState!.timeRemainingSeconds ~/ 60;
    int secs = _gameState!.timeRemainingSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.white, // Manual theme is bright/paper
      appBar: AppBar(
         backgroundColor: Colors.blue.shade900,
         title: const Text("EXPERT (PLAYER 2)", style: TextStyle(color: Colors.white)),
         automaticallyImplyLeading: false,
         actions: [
            TextButton(
               onPressed: () {
                  _service.leaveRoom();
                  Navigator.of(context).pop();
               },
               child: const Text("Skip", style: TextStyle(color: Colors.white)),
            )
         ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Header
            Container(
               color: Colors.blue.shade50,
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                        children: [
                           const Icon(Icons.timer, color: Colors.red),
                           const SizedBox(width: 8),
                           Text(
                              "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}",
                              style: GoogleFonts.shareTechMono(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)
                           ),
                        ],
                     ),
                     Row(
                        children: [
                           Text("STRIKES: ", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                           Text("${_gameState!.strikes}/${_gameState!.maxStrikes}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))
                        ],
                     )
                  ],
               ),
            ),
            
            // Manual Content
            Expanded(
               child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                     Text("DEFUSAL MANUAL", style: GoogleFonts.merriweather(fontSize: 32, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Text("Subject: Simple Wires", style: GoogleFonts.merriweather(fontSize: 20, fontStyle: FontStyle.italic)),
                     const Divider(thickness: 2),
                     const SizedBox(height: 16),
                     
                     Text(
                        "Wires are the lifeblood of explosive electronics. Wait, no, that's electricity. Wires are more like the veins. The veins of the bomb.",
                        style: GoogleFonts.merriweather(fontSize: 14, height: 1.5)
                     ),
                     const SizedBox(height: 24),
                     
                     Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text("5 Wires Condition", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.underline)),
                              const SizedBox(height: 16),
                              
                              _buildRuleItem("1", "If there is exactly one black wire and the serial number is odd, cut the fourth wire."),
                              _buildRuleItem("2", "Otherwise, if there is exactly one red wire and there is more than one yellow wire, cut the first wire."),
                              _buildRuleItem("3", "Otherwise, if there are no black wires, cut the second wire."), // This is the fallback for the simulated mock
                              _buildRuleItem("4", "Otherwise, cut the first wire.")
                           ],
                        ),
                     ),
                     
                     const SizedBox(height: 32),
                     Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.yellow.shade100,
                        child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 16),
                              Expanded(
                                 child: Text(
                                    "IMPORTANT: You cannot see the bomb. Ask the Defuser to describe the wires (top to bottom) and the Serial Number to you. Tell them which wire to cut.",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
                                 )
                              )
                           ],
                        )
                     )
                  ],
               ),
            )
          ],
        ),
      )
    );
  }
  
  Widget _buildRuleItem(String num, String text) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text("$num. ", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
              Expanded(child: Text(text, style: GoogleFonts.merriweather())),
           ],
        ),
     );
  }
}
