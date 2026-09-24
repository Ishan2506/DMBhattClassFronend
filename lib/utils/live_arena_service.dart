import 'dart:async';

import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Server-aligned clock for Live Arena countdowns.
///
/// Countdowns are display only; the server decides when an exam opens and
/// closes. Aligning to the server's clock just keeps the display honest on
/// phones whose time is off.
class LiveArenaClock {
  static Duration _offset = Duration.zero;

  static void sync(dynamic serverTime) {
    final t = DateTime.tryParse(serverTime?.toString() ?? '');
    if (t != null) _offset = t.difference(DateTime.now());
  }

  static DateTime now() => DateTime.now().add(_offset);

  static String countdown(DateTime target) {
    var d = target.difference(now());
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays;
    final hms =
        '${(d.inHours % 24).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return days > 0 ? '${days}d $hms' : hms;
  }
}

/// Live Arena realtime connection (Socket.IO).
///
/// Screens call [join] when they open and [leave] when they close. A room joined
/// with `watch: true` (list screen) only receives numbers; a normal join
/// (waiting room / exam) also counts the student as online. The socket is
/// closed when no screen needs it, so presence ends when the student leaves
/// Live Arena.
class LiveArenaSocket {
  LiveArenaSocket._();
  static final LiveArenaSocket instance = LiveArenaSocket._();

  io.Socket? _socket;
  String? _socketToken;
  final Map<String, int> _presenceRefs = {};
  final Map<String, int> _watchRefs = {};

  final _stats = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<Map<String, dynamic>>.broadcast();
  final _leaderboard = StreamController<Map<String, dynamic>>.broadcast();

  /// { examId, queueCount, onlineCount, status, startAt, endAt, serverTime }
  Stream<Map<String, dynamic>> get stats => _stats.stream;

  /// { examId, status, startAt, endAt, serverTime } — phase changed
  Stream<Map<String, dynamic>> get status => _status.stream;

  /// { examId, total, entries } — top 10 changed
  Stream<Map<String, dynamic>> get leaderboard => _leaderboard.stream;

  static String get _serverRoot => ApiService.baseUrl.replaceAll('/api', '');

  void _ensureConnected() {
    final token = ApiService.userToken;
    if (token == null || token.isEmpty || ApiService.isGuest) return;

    // A different login since the socket was opened: reconnect as that user.
    if (_socket != null && _socketToken != token) _dispose();
    if (_socket != null) return;

    _socketToken = token;
    final socket = io.io(
      _serverRoot,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) {
      // Re-enter every room after a (re)connect so counts and presence recover
      // on their own after a network drop or a server restart.
      for (final id in {..._watchRefs.keys, ..._presenceRefs.keys}) {
        _emitJoin(id);
      }
    });
    socket.onConnectError((err) {
      if (kDebugMode) debugPrint('[LiveArena] connect error: $err');
    });
    socket.on('liveExam:stats', (d) => _forward(_stats, d));
    socket.on('liveExam:status', (d) => _forward(_status, d));
    socket.on('liveExam:leaderboard', (d) => _forward(_leaderboard, d));

    _socket = socket;
    socket.connect();
  }

  void _forward(StreamController<Map<String, dynamic>> sink, dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      LiveArenaClock.sync(map['serverTime']);
      sink.add(map);
    }
  }

  void _emitJoin(String examId) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    final watch = (_presenceRefs[examId] ?? 0) == 0;
    socket.emitWithAck(
      'liveExam:join',
      {'examId': examId, 'watch': watch},
      ack: (data) {
        if (data is Map && data['ok'] == true) _forward(_stats, data);
      },
    );
  }

  /// [watch] = only follow the numbers without counting as online.
  void join(String examId, {bool watch = false}) {
    final refs = watch ? _watchRefs : _presenceRefs;
    refs[examId] = (refs[examId] ?? 0) + 1;
    _ensureConnected();
    _emitJoin(examId);
  }

  void leave(String examId, {bool watch = false}) {
    final refs = watch ? _watchRefs : _presenceRefs;
    final left = (refs[examId] ?? 1) - 1;
    if (left <= 0) {
      refs.remove(examId);
    } else {
      refs[examId] = left;
    }

    final stillWatched = _watchRefs.containsKey(examId);
    final stillPresent = _presenceRefs.containsKey(examId);
    if (!stillPresent && stillWatched) {
      _emitJoin(examId); // downgrade to watching
    } else if (!stillPresent && !stillWatched) {
      _socket?.emit('liveExam:leave', {'examId': examId});
    }

    if (_watchRefs.isEmpty && _presenceRefs.isEmpty) _dispose();
  }

  void _dispose() {
    _socket?.dispose();
    _socket = null;
    _socketToken = null;
  }
}
