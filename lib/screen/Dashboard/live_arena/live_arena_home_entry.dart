import 'dart:async';
import 'dart:convert';

import 'package:dm_bhatt_tutions/model/live_exam.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_detail_screen.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home-dashboard entry to Live Arena.
///
/// Shows a single reminder banner when an exam is relevant right now (in
/// progress, live, or coming up within a day); otherwise a slim entry tile.
/// A dismissed banner stays hidden for that exam until its state changes
/// (e.g. from "starts soon" to "is live"), so it never nags.
class LiveArenaHomeEntry extends StatefulWidget {
  const LiveArenaHomeEntry({super.key});

  @override
  State<LiveArenaHomeEntry> createState() => _LiveArenaHomeEntryState();
}

class _LiveArenaHomeEntryState extends State<LiveArenaHomeEntry>
    with WidgetsBindingObserver {
  static const _reminderWindow = Duration(hours: 24);

  LiveExam? _featured;
  Set<String> _dismissed = {};
  Timer? _ticker;
  bool _refetchedAtStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  String _dismissKey(LiveExam e) => '${e.id}:${e.myState}';

  Future<void> _load() async {
    // Guests can't hold a queue place, so only the entry tile is shown to them.
    if (await GuestUtils.isGuest()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissed = (prefs.getStringList('live_arena_dismissed') ?? []).toSet();

      final res = await ApiService.getLiveExams(silent: true);
      if (!mounted || res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      LiveArenaClock.sync(data['serverTime']);
      final exams = (data['exams'] as List? ?? [])
          .map((e) => LiveExam.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _featured = _pick(exams);
        _refetchedAtStart = false;
      });
      _ticker?.cancel();
      if (_featured != null) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      }
    } catch (_) {
      // Banner is optional; stay quiet on network errors.
    }
  }

  /// Most urgent first: resume > live > queued/upcoming soon.
  LiveExam? _pick(List<LiveExam> exams) {
    int rank(LiveExam e) => switch (e.myState) {
          'IN_PROGRESS' => 0,
          'LIVE' => 1,
          'IN_QUEUE' => 2,
          'UPCOMING' => 3,
          _ => 99,
        };
    final now = LiveArenaClock.now();
    final candidates = exams.where((e) {
      if (rank(e) == 99 || _dismissed.contains(_dismissKey(e))) return false;
      if (e.myState == 'UPCOMING' || e.myState == 'IN_QUEUE') {
        return e.startAt.difference(now) <= _reminderWindow;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.startAt.compareTo(b.startAt);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  void _onTick() {
    if (!mounted) return;
    final e = _featured;
    if (e == null) return;
    setState(() {});
    final target = e.status == 'LIVE' ? e.endAt : e.startAt;
    if (!_refetchedAtStart && !LiveArenaClock.now().isBefore(target)) {
      _refetchedAtStart = true;
      Future.delayed(const Duration(seconds: 2), _load);
    }
  }

  Future<void> _dismiss() async {
    final e = _featured;
    if (e == null) return;
    _dismissed.add(_dismissKey(e));
    final prefs = await SharedPreferences.getInstance();
    // Keep the list small: only the most recent dismissals matter.
    final list = _dismissed.toList();
    await prefs.setStringList('live_arena_dismissed', list.length > 50 ? list.sublist(list.length - 50) : list);
    _ticker?.cancel();
    if (mounted) setState(() => _featured = null);
  }

  Future<void> _open(Widget screen) async {
    if (await GuestUtils.isGuest()) {
      if (mounted) {
        GuestUtils.showGuestRestrictionDialog(
          context,
          message: 'Register to take part in Live Arena exams and appear on the leaderboard.',
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final e = _featured;
    return e == null ? _entryTile() : _banner(e);
  }

  Widget _entryTile() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(const LiveArenaScreen()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Arena', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text(
                        'Compete live with your class',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(LiveExam e) {
    final live = e.myState == 'LIVE' || e.myState == 'IN_PROGRESS';
    final color = live ? Colors.green.shade700 : Colors.red.shade600;
    final minutesToStart = e.startAt.difference(LiveArenaClock.now()).inMinutes;

    final String heading;
    final String line;
    final String cta;
    switch (e.myState) {
      case 'IN_PROGRESS':
        heading = '🟢 YOUR EXAM IS IN PROGRESS';
        line = '${e.title} — ends in ${LiveArenaClock.countdown(e.endAt)}.';
        cta = 'RESUME EXAM';
        break;
      case 'LIVE':
        heading = '🟢 YOUR EXAM IS LIVE';
        line = '${e.title} has started.';
        cta = 'ENTER EXAM';
        break;
      default:
        heading = minutesToStart <= 60 ? '🔴 LIVE EXAM REMINDER' : '⏰ Upcoming Live Exam';
        line = minutesToStart <= 60
            ? '${e.title} starts in ${LiveArenaClock.countdown(e.startAt)}.'
            : 'Your ${e.title} starts at ${formatLiveTime(e.startAt)}${_dayLabel(e.startAt)}.';
        cta = e.canJoinQueue ? 'JOIN QUEUE' : 'VIEW EXAM';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(LiveExamDetailScreen(examId: e.id)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      if (e.myState != 'IN_PROGRESS')
                        InkWell(
                          onTap: _dismiss,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(line, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  ),
                  if (e.queueCount > 0 && !live) ...[
                    const SizedBox(height: 4),
                    Text(
                      '👥 ${e.queueCount} student${e.queueCount == 1 ? ' is' : 's are'} already waiting.',
                      style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _open(LiveExamDetailScreen(examId: e.id)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(cta, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = LiveArenaClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return ' today';
    if (diff == 1) return ' tomorrow';
    return ' on ${formatLiveDate(d)}';
  }
}
