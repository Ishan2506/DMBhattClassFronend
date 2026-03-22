import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/multiplayer_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/escape_room/escape_room_defuser_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/escape_room/escape_room_expert_screen.dart';

class EscapeLobbyScreen extends StatefulWidget {
  const EscapeLobbyScreen({super.key});

  @override
  State<EscapeLobbyScreen> createState() => _EscapeLobbyScreenState();
}

class _EscapeLobbyScreenState extends State<EscapeLobbyScreen> {
  final MultiplayerService _service = MultiplayerService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _service.onError = (err) {
      if (mounted) {
        setState(() {
          _errorMessage = err;
          _isLoading = false;
        });
      }
    };
    
    _service.onStateChanged = (state) {
      if (!mounted || state == null) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to respective screens when game is 'playing'
      if (state.status == GameStatus.playing) {
          _service.startPolling(); // Start the timer loop
          
          if (_service.currentUserRole == "defuser") {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EscapeRoomDefuserScreen()));
          } else if (_service.currentUserRole == "expert") {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EscapeRoomExpertScreen()));
          }
      }
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    // In a real app, clear listeners or handle lifecycle
    super.dispose();
  }

  void _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your name.");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    await _service.createRoom(_nameController.text.trim());
  }

  void _joinRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your name.");
      return;
    }
    if (_codeController.text.trim().length != 4) {
       setState(() => _errorMessage = "Enter a valid 4-digit code.");
       return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    await _service.joinRoom(_codeController.text.trim(), _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Escape Room Lobby"),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.meeting_room_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                "Co-op Escape Room",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Grab a friend! One of you creates a room (The Defuser), the other joins (The Expert). You must communicate to survive.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                ),

              if (_service.currentRoomId != null) 
                _buildWaitingRoom()
              else 
                _buildEntryForm(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWaitingRoom() {
     return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: Column(
              children: [
                 Text("Room Created!", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 Text("Tell your friend to enter this code:", style: GoogleFonts.poppins(fontSize: 14)),
                 const SizedBox(height: 8),
                 Text(
                    _service.currentRoomId ?? "",
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.blue),
                 ),
                 const SizedBox(height: 24),
                 const CustomLoader(),
                 const SizedBox(height: 16),
                 Text("Waiting for Expert to join...", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                 const SizedBox(height: 24),
                 OutlinedButton(
                    onPressed: () {
                        _service.leaveRoom();
                        setState((){});
                    },
                    child: const Text("Cancel & Leave Room"),
                 )
              ],
           ),
        ),
     );
  }

  Widget _buildEntryForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Your Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CustomLoader())
                        : const Text("Create Room"),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("OR")),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: "4-Digit Room Code",
                prefixIcon: Icon(Icons.dialpad),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _joinRoom,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text("Join Room"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
