import 'dart:math';

// A mock service for real-time multiplayer.
// In a real production app, this would use Firebase Realtime Database or Socket.IO.
// For this frontend-only test, we'll simulate a delayed response local server.

class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  // Simulated Database
  final Map<String, EscapeGameState> _activeRooms = {};
  String? _currentRoomId;
  String? _currentUserRole; // "defuser" or "expert"

  // Observers
  Function(EscapeGameState?)? onStateChanged;
  Function(String)? onError;

  String? get currentRoomId => _currentRoomId;
  String? get currentUserRole => _currentUserRole;

  Future<void> createRoom(String playerName) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
    
    // Generate 4 digit code
    String code = (Random().nextInt(9000) + 1000).toString();
    
    // Ensure uniqueness
    while (_activeRooms.containsKey(code)) {
      code = (Random().nextInt(9000) + 1000).toString();
    }

    _activeRooms[code] = EscapeGameState(
      roomId: code,
      player1Name: playerName,
      status: GameStatus.waiting,
      puzzleSeed: Random().nextInt(100), // Determines wire colors/rules
    );

    _currentRoomId = code;
    _currentUserRole = "defuser"; // Creator is always the defuser

    _notifyState();
  }

  Future<void> joinRoom(String code, String playerName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_activeRooms.containsKey(code)) {
      onError?.call("Room not found!");
      return;
    }

    var state = _activeRooms[code]!;
    if (state.status != GameStatus.waiting) {
      onError?.call("Room is already full or in progress!");
      return;
    }

    state.player2Name = playerName;
    state.status = GameStatus.playing;
    state.startTime = DateTime.now();
    
    // Initialize wires based on the seed
    final r = Random(state.puzzleSeed);
    List<String> availableColors = ['red', 'blue', 'green', 'yellow', 'white', 'black'];
    state.wires = List.generate(5, (_) => availableColors[r.nextInt(availableColors.length)]);
    state.wiresCut = [false, false, false, false, false];
    
    // Ensure at least one correct solution is logically sound
    // Determine the winning wire based on rules (simulating expert manual)
    int redCount = state.wires.where((w) => w == 'red').length;
    int lastWireBlue = state.wires.last == 'blue' ? 1 : 0;
    
    if (redCount > 1 && state.serialNumberIsOdd) {
      state.correctWireIndex = state.wires.lastIndexOf('red');
    } else if (lastWireBlue == 1 && state.wires.isEmpty) {
      // Impossible condition just for example
      state.correctWireIndex = 0;
    } else {
      state.correctWireIndex = 2; // Default fallback rule
    }

    _currentRoomId = code;
    _currentUserRole = "expert"; // Joiner is always the expert

    _notifyState();
  }

  Future<void> cutWire(int index) async {
    if (_currentRoomId == null) return;
    var state = _activeRooms[_currentRoomId!];
    if (state == null || state.status != GameStatus.playing) return;

    // In local simulation, execute instantly.
    // In real app, push to Firebase here.
    state.wiresCut[index] = true;

    if (index == state.correctWireIndex) {
      state.status = GameStatus.won;
    } else {
      state.strikes++;
      if (state.strikes >= state.maxStrikes) {
        state.status = GameStatus.lost;
      }
    }

    _notifyState();
  }

  Future<void> leaveRoom() async {
    if (_currentRoomId != null) {
      _activeRooms.remove(_currentRoomId);
      _currentRoomId = null;
      _currentUserRole = null;
      _notifyState();
    }
  }

  void _notifyState() {
    if (_currentRoomId != null && _activeRooms.containsKey(_currentRoomId)) {
      onStateChanged?.call(_activeRooms[_currentRoomId]);
    } else {
      onStateChanged?.call(null);
    }
  }

  // Polling simulation for Expert to see changes made by Defuser
  void startPolling() {
    // In a real app with WebSockets/Firebase, this isn't needed.
    // We just trigger state updates periodically for the demo to feel "live".
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_currentRoomId != null && _activeRooms.containsKey(_currentRoomId)) {
          var state = _activeRooms[_currentRoomId!]!;
          if (state.status == GameStatus.playing && state.startTime != null) {
              int elapsedSeconds = DateTime.now().difference(state.startTime!).inSeconds;
              state.timeRemainingSeconds = state.totalTimeSeconds - elapsedSeconds;
              if (state.timeRemainingSeconds <= 0) {
                  state.timeRemainingSeconds = 0;
                  state.status = GameStatus.lost;
              }
              _notifyState();
          }
      }
      return _currentRoomId != null;
    });
  }
}

enum GameStatus { waiting, playing, won, lost }

class EscapeGameState {
  String roomId;
  String player1Name; // Defuser
  String? player2Name; // Expert
  GameStatus status;
  
  int puzzleSeed;
  
  // Game constraints
  int totalTimeSeconds = 300; // 5 mins
  int timeRemainingSeconds = 300;
  DateTime? startTime;
  
  int strikes = 0;
  int maxStrikes = 3;

  // Bomb specifics
  bool serialNumberIsOdd = false; // Decided by seed
  List<String> wires = [];
  List<bool> wiresCut = [];
  int correctWireIndex = 0;

  EscapeGameState({
    required this.roomId,
    required this.player1Name,
    this.player2Name,
    required this.status,
    required this.puzzleSeed,
  }) {
    serialNumberIsOdd = puzzleSeed % 2 != 0;
  }
}
