import 'dart:async';
import 'dart:convert';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/model/live_exam.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_attempt_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_leaderboard_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_result_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Waiting room / details for one Live Exam. Being on this screen counts the
/// student as "online" for the exam.
class LiveExamDetailScreen extends StatefulWidget {
  final String examId;
  const LiveExamDetailScreen({super.key, required this.examId});

  @override
  State<LiveExamDetailScreen> createState() => _LiveExamDetailScreenState();
}

class _LiveExamDetailScreenState extends State<LiveExamDetailScreen>
    with WidgetsBindingObserver {
  LiveExam? _exam;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _ticker;
  Timer? _refetch;
  StreamSubscription? _statsSub;
  StreamSubscription? _statusSub;
  bool _refetchedAtZero = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LiveArenaSocket.instance.join(widget.examId);
    _statsSub = LiveArenaSocket.instance.stats.listen((s) {
      if (s['examId'] != widget.examId || _exam == null) return;
      setState(() {
        _exam!.queueCount = (s['queueCount'] as num?)?.toInt() ?? _exam!.queueCount;
        _exam!.onlineCount = (s['onlineCount'] as num?)?.toInt() ?? _exam!.onlineCount;
      });
      if (s['status'] != null && s['status'] != _exam!.status) _scheduleRefetch();
    });
    _statusSub = LiveArenaSocket.instance.status.listen((s) {
      if (s['examId'] != widget.examId) return;
      if (s['status'] == 'LIVE' && mounted) {
        CustomToast.showSuccess(context, 'The exam is LIVE now!');
      }
      _scheduleRefetch();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _refetch?.cancel();
    _statsSub?.cancel();
    _statusSub?.cancel();
    LiveArenaSocket.instance.leave(widget.examId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app: the exam may have started meanwhile.
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
    final exam = _exam;
    if (exam == null) return;
    // Local countdown reached the start: confirm with the server (it decides).
    final target = exam.status == 'LIVE' ? exam.endAt : exam.startAt;
    final reached = !LiveArenaClock.now().isBefore(target);
    if (reached && !_refetchedAtZero && !exam.isOver) {
      _refetchedAtZero = true;
      Future.delayed(const Duration(seconds: 2), () => _load(silent: true));
    }
  }

  void _scheduleRefetch() {
    _refetch?.cancel();
    _refetch = Timer(const Duration(milliseconds: 500), () => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.getLiveExam(widget.examId);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        LiveArenaClock.sync(data['serverTime']);
        setState(() {
          _exam = LiveExam.fromJson(Map<String, dynamic>.from(data['exam']));
          _error = null;
          _loading = false;
          _refetchedAtZero = false;
        });
      } else {
        setState(() {
          _error = ApiService.getErrorMessage(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error ??= 'Could not load this exam.';
        _loading = false;
      });
    }
  }

  Future<void> _joinQueue() async {
    setState(() => _busy = true);
    final res = await ApiService.joinLiveExamQueue(widget.examId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.statusCode == 200) {
      CustomToast.showSuccess(context, 'You are in the queue');
    } else {
      CustomToast.showError(context, ApiService.getErrorMessage(res.body));
    }
    _load(silent: true);
  }

  Future<void> _leaveQueue() async {
    setState(() => _busy = true);
    final res = await ApiService.leaveLiveExamQueue(widget.examId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.statusCode != 200) {
      CustomToast.showError(context, ApiService.getErrorMessage(res.body));
    }
    _load(silent: true);
  }

  Future<void> _enter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveExamAttemptScreen(examId: widget.examId)),
    );
    if (mounted) _load(silent: true);
  }

  Future<void> _retake() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Practice Retake', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Only your FIRST attempt counts on the leaderboard. This retake is for practice and will not change your rank.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start Practice')),
        ],
      ),
    );
    if (ok == true) _enter();
  }

  Future<void> _viewResult() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveExamResultScreen(examId: widget.examId)),
    );
    if (mounted) _load(silent: true);
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveExamLeaderboardScreen(examId: widget.examId, title: _exam?.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _exam?.title ?? 'Live Exam'),
      body: _loading
          ? const CustomLoader()
          : _exam == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error ?? 'Exam not found', textAlign: TextAlign.center, style: GoogleFonts.poppins()),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(silent: true),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _hero(_exam!),
                      const SizedBox(height: 16),
                      _details(_exam!),
                      const SizedBox(height: 16),
                      ..._actions(_exam!),
                    ],
                  ),
                ),
    );
  }

  Widget _hero(LiveExam exam) {
    final colorScheme = Theme.of(context).colorScheme;
    final running = exam.status == 'LIVE';
    final showClock = !exam.isOver && exam.myState != 'SUBMITTED';
    final headline = switch (exam.myState) {
      'IN_QUEUE' => 'You are in the queue.',
      'LIVE' => 'EXAM IS LIVE',
      'IN_PROGRESS' => 'Your exam is in progress',
      'SUBMITTED' => 'Exam submitted 🎉',
      'COMPLETED' => 'Exam completed',
      'EXPIRED' => 'This exam has ended',
      'CANCELLED' => 'This exam was cancelled',
      _ => 'Upcoming Live Exam',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (showClock) ...[
            const SizedBox(height: 12),
            Text(
              running ? 'Ends in' : 'Exam starts in',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            Text(
              LiveArenaClock.countdown(running ? exam.endAt : exam.startAt),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _heroStat('Students waiting', exam.queueCount, Icons.groups_rounded),
              Container(width: 1, height: 36, color: Colors.white24),
              _heroStat('Currently online', exam.onlineCount, Icons.circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, int value, IconData icon) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: icon == Icons.circle ? Colors.greenAccent : Colors.white, size: icon == Icons.circle ? 10 : 18),
              const SizedBox(width: 6),
              Text('$value', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _details(LiveExam exam) {
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
              const Spacer(),
              Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${exam.subject} • Class ${exam.std}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                LiveStateChip(myState: exam.myState),
              ],
            ),
            if (exam.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(exam.description, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
            ],
            const Divider(height: 24),
            row(Icons.event_rounded, 'Date', formatLiveDate(exam.startAt)),
            row(Icons.schedule_rounded, 'Start time', formatLiveTime(exam.startAt)),
            row(Icons.timer_outlined, 'Duration', '${exam.durationMinutes} minutes'),
            row(Icons.help_outline_rounded, 'Questions', '${exam.questionCount}'),
            row(Icons.star_outline_rounded, 'Total marks', formatMarks(exam.totalMarks)),
            if (exam.passingMarks > 0) row(Icons.flag_outlined, 'Passing marks', formatMarks(exam.passingMarks)),
            if (exam.instructions.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Instructions', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(exam.instructions, style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
            ],
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only your first attempt counts on the leaderboard.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(LiveExam exam) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = primaryActionFor(exam);

    Widget button(String label, VoidCallback? onTap, {Color? color, bool outlined = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: outlined
                ? OutlinedButton(
                    onPressed: _busy ? null : onTap,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton(
                    onPressed: _busy ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color ?? colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
          ),
        );

    final out = <Widget>[];
    switch (primary.action) {
      case LiveAction.joinQueue:
        out.add(button('JOIN QUEUE', _joinQueue));
        break;
      case LiveAction.enter:
        out.add(button('START EXAM', _enter, color: Colors.green.shade600));
        break;
      case LiveAction.resume:
        out.add(button('RESUME EXAM', _enter, color: Colors.green.shade600));
        break;
      case LiveAction.viewResult:
        out.add(button('VIEW RESULT', _viewResult));
        break;
      case LiveAction.none:
        if (exam.myState == 'UPCOMING') {
          out.add(button(primary.label, null));
        }
        break;
    }
    if (exam.canRetake) out.add(button('Practice Retake', _retake, outlined: true));
    if (exam.canLeaveQueue) out.add(button('Leave Queue', _leaveQueue, outlined: true));
    if (exam.status == 'LIVE' || exam.status == 'COMPLETED') {
      out.add(button('Leaderboard', _openLeaderboard, outlined: true));
    }
    return out;
  }
}
