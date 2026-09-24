import 'dart:async';
import 'dart:convert';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/model/live_exam.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_attempt_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_detail_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_result_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Live Arena: scheduled exams every student in the class sits together.
class LiveArenaScreen extends StatefulWidget {
  const LiveArenaScreen({super.key});

  @override
  State<LiveArenaScreen> createState() => _LiveArenaScreenState();
}

class _LiveArenaScreenState extends State<LiveArenaScreen> {
  static const _maxWatchedRooms = 20;

  List<LiveExam> _exams = [];
  bool _loading = true;
  String? _error;
  final Set<String> _watching = {};
  final Set<String> _busy = {};
  Timer? _ticker;
  StreamSubscription? _statsSub;
  StreamSubscription? _statusSub;
  Timer? _refetchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _statsSub = LiveArenaSocket.instance.stats.listen((s) {
      final exam = _find(s['examId']);
      if (exam == null) return;
      setState(() {
        exam.queueCount = (s['queueCount'] as num?)?.toInt() ?? exam.queueCount;
        exam.onlineCount = (s['onlineCount'] as num?)?.toInt() ?? exam.onlineCount;
      });
      if (s['status'] != null && s['status'] != exam.status) _scheduleRefetch();
    });
    // A phase change (e.g. LIVE) changes which actions are allowed: ask the server.
    _statusSub = LiveArenaSocket.instance.status.listen((s) {
      if (_find(s['examId']) != null) _scheduleRefetch();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _refetchDebounce?.cancel();
    _statsSub?.cancel();
    _statusSub?.cancel();
    for (final id in _watching) {
      LiveArenaSocket.instance.leave(id, watch: true);
    }
    super.dispose();
  }

  LiveExam? _find(dynamic id) {
    for (final e in _exams) {
      if (e.id == id?.toString()) return e;
    }
    return null;
  }

  void _scheduleRefetch() {
    _refetchDebounce?.cancel();
    _refetchDebounce = Timer(const Duration(milliseconds: 600), () => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await ApiService.getLiveExams(silent: silent);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        LiveArenaClock.sync(data['serverTime']);
        final exams = (data['exams'] as List? ?? [])
            .map((e) => LiveExam.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _exams = exams;
          _error = null;
          _loading = false;
        });
        _syncRooms();
      } else {
        setState(() {
          _error = ApiService.getErrorMessage(res.body);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Live Arena. Pull to retry.';
        _loading = false;
      });
    }
  }

  /// Follow live numbers for exams that are still ahead or running.
  void _syncRooms() {
    final wanted = _exams
        .where((e) => !e.isOver)
        .take(_maxWatchedRooms)
        .map((e) => e.id)
        .toSet();
    for (final id in _watching.difference(wanted)) {
      LiveArenaSocket.instance.leave(id, watch: true);
    }
    for (final id in wanted.difference(_watching)) {
      LiveArenaSocket.instance.join(id, watch: true);
    }
    _watching
      ..clear()
      ..addAll(wanted);
  }

  Future<void> _openDetail(LiveExam exam) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveExamDetailScreen(examId: exam.id)),
    );
    if (mounted) _load(silent: true);
  }

  Future<void> _runAction(LiveExam exam, LiveAction action) async {
    switch (action) {
      case LiveAction.joinQueue:
        setState(() => _busy.add(exam.id));
        final res = await ApiService.joinLiveExamQueue(exam.id);
        if (!mounted) return;
        setState(() => _busy.remove(exam.id));
        if (res.statusCode == 200) {
          CustomToast.showSuccess(context, 'You are in the queue');
        } else {
          CustomToast.showError(context, ApiService.getErrorMessage(res.body));
        }
        _load(silent: true);
        break;
      case LiveAction.enter:
      case LiveAction.resume:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LiveExamAttemptScreen(examId: exam.id)),
        );
        if (mounted) _load(silent: true);
        break;
      case LiveAction.viewResult:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LiveExamResultScreen(examId: exam.id)),
        );
        if (mounted) _load(silent: true);
        break;
      case LiveAction.none:
        _openDetail(exam);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _exams.where((e) => !e.isOver).toList();
    final past = _exams.where((e) => e.isOver).toList().reversed.toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Live Arena'),
      body: _loading
          ? const CustomLoader()
          : RefreshIndicator(
              onRefresh: () => _load(silent: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_error != null)
                    _message(_error!, Icons.cloud_off_rounded)
                  else if (_exams.isEmpty)
                    _message(
                      'No live exams scheduled for your class yet.\nYou will be reminded when one is coming up.',
                      Icons.event_available_rounded,
                    )
                  else ...[
                    if (upcoming.isNotEmpty) ...[
                      _sectionTitle('Live & Upcoming'),
                      ...upcoming.map(_card),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionTitle('Past'),
                      ...past.map(_card),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );

  Widget _message(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Widget _card(LiveExam exam) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = primaryActionFor(exam);
    final showCountdown = exam.myState == 'UPCOMING' ||
        exam.myState == 'IN_QUEUE' ||
        exam.myState == 'LIVE' ||
        exam.myState == 'IN_PROGRESS';
    final running = exam.status == 'LIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${exam.subject} • Class ${exam.std}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  LiveStateChip(myState: exam.myState),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  LiveCountPill(icon: Icons.event_rounded, color: colorScheme.primary, text: formatLiveDate(exam.startAt)),
                  LiveCountPill(icon: Icons.schedule_rounded, color: colorScheme.primary, text: formatLiveTime(exam.startAt)),
                  LiveCountPill(icon: Icons.timer_outlined, color: colorScheme.primary, text: '${exam.durationMinutes} min'),
                  LiveCountPill(icon: Icons.star_outline_rounded, color: colorScheme.primary, text: '${formatMarks(exam.totalMarks)} marks'),
                ],
              ),
              if (showCountdown) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        running ? 'Ends in' : 'Starts in',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const Spacer(),
                      Text(
                        LiveArenaClock.countdown(running ? exam.endAt : exam.startAt),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    LiveCountPill(icon: Icons.groups_rounded, color: Colors.orange.shade700, text: '${exam.queueCount} Waiting'),
                    const SizedBox(width: 16),
                    LiveCountPill(icon: Icons.circle, color: Colors.green.shade600, text: '${exam.onlineCount} Online'),
                  ],
                ),
              ],
              if (exam.firstAttemptMarks != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Your score: ${formatMarks(exam.firstAttemptMarks)} / ${formatMarks(exam.totalMarks)}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              if (primary.label.isNotEmpty &&
                  exam.myState != 'EXPIRED' &&
                  exam.myState != 'CANCELLED') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: primary.action == LiveAction.none || _busy.contains(exam.id)
                        ? null
                        : () => _runAction(exam, primary.action),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary.action == LiveAction.enter || primary.action == LiveAction.resume
                          ? Colors.green.shade600
                          : colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _busy.contains(exam.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            primary.label,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
