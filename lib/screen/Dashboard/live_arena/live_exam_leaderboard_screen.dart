import 'dart:async';
import 'dart:convert';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Live leaderboard for one exam. Ranks come from the server and use each
/// student's FIRST attempt only.
class LiveExamLeaderboardScreen extends StatefulWidget {
  final String examId;
  final String? title;
  const LiveExamLeaderboardScreen({super.key, required this.examId, this.title});

  @override
  State<LiveExamLeaderboardScreen> createState() => _LiveExamLeaderboardScreenState();
}

class _LiveExamLeaderboardScreenState extends State<LiveExamLeaderboardScreen> {
  static const _pageSize = 50;

  final List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic>? _me;
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  StreamSubscription? _boardSub;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    LiveArenaSocket.instance.join(widget.examId, watch: true);
    _boardSub = LiveArenaSocket.instance.leaderboard.listen((b) {
      if (b['examId'] != widget.examId) return;
      // Someone submitted: refresh what is on screen (coalesced).
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 800), () => _reload(silent: true));
    });
    _reload();
  }

  @override
  void dispose() {
    _boardSub?.cancel();
    _refreshDebounce?.cancel();
    LiveArenaSocket.instance.leave(widget.examId, watch: true);
    super.dispose();
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final pages = _page == 0 ? 1 : _page;
    final fresh = <Map<String, dynamic>>[];
    try {
      for (var p = 1; p <= pages; p++) {
        final data = await _fetch(p);
        if (data == null) return;
        fresh.addAll(_parse(data));
        if (p == 1) {
          _me = data['me'] != null ? Map<String, dynamic>.from(data['me']) : null;
          _total = (data['total'] as num?)?.toInt() ?? 0;
        }
      }
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(fresh);
        _page = pages;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error ??= 'Could not load the leaderboard.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _entries.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _fetch(_page + 1);
      if (data != null && mounted) {
        setState(() {
          _entries.addAll(_parse(data));
          _page++;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<Map<String, dynamic>?> _fetch(int page) async {
    final res = await ApiService.getLiveExamLeaderboard(widget.examId, page: page, limit: _pageSize);
    if (res.statusCode != 200) {
      if (mounted) {
        setState(() {
          _error = ApiService.getErrorMessage(res.body);
          _loading = false;
        });
      }
      return null;
    }
    final data = Map<String, dynamic>.from(jsonDecode(res.body));
    LiveArenaClock.sync(data['serverTime']);
    return data;
  }

  List<Map<String, dynamic>> _parse(Map<String, dynamic> data) =>
      (data['entries'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.title != null ? '${widget.title}' : 'Live Leaderboard'),
      body: _loading
          ? const CustomLoader()
          : RefreshIndicator(
              onRefresh: () => _reload(silent: true),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) _loadMore();
                  return false;
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('LIVE LEADERBOARD', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                        const Spacer(),
                        Text('$_total ranked', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ranked by first-attempt marks, then time taken.',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    if (_me != null) _meCard(_me!),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins()),
                      )
                    else if (_entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No submissions yet. Be the first!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey.shade600),
                        ),
                      )
                    else ...[
                      _header(),
                      ..._entries.map(_row),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _meCard(Map<String, dynamic> me) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text('Your rank', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('#${me['rank']}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(width: 14),
          Text(
            '${formatMarks(me['obtainedMarks'] as num?)} / ${formatMarks(me['totalMarks'] as num?)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final style = GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('Rank', style: style)),
          Expanded(child: Text('Student', style: style)),
          SizedBox(width: 64, child: Text('Marks', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 64, child: Text('Time', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> e) {
    final rank = (e['rank'] as num).toInt();
    final medal = rank == 1
        ? const Color(0xFFFFC107)
        : rank == 2
            ? const Color(0xFFB0BEC5)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : null;
    final isMe = _me != null && _me!['rank'] == rank;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: medal != null
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: medal,
                    child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                : Text('$rank', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(
              e['name']?.toString() ?? 'Student',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontWeight: isMe ? FontWeight.bold : FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              formatMarks(e['obtainedMarks'] as num?),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              formatTimeTaken(e['timeTakenMs'] as num?),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
