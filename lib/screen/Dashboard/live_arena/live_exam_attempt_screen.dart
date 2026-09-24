import 'dart:async';
import 'dart:convert';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_result_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sitting a Live Exam. The server hands out the questions (without answers),
/// owns the deadline and grades the submission; this screen only collects the
/// selected option keys and autosaves them so a refresh or a dropped
/// connection loses nothing.
class LiveExamAttemptScreen extends StatefulWidget {
  final String examId;
  const LiveExamAttemptScreen({super.key, required this.examId});

  @override
  State<LiveExamAttemptScreen> createState() => _LiveExamAttemptScreenState();
}

class _LiveExamAttemptScreenState extends State<LiveExamAttemptScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  String? _attemptId;
  int _attemptNumber = 1;
  bool _isFirstAttempt = true;
  DateTime? _deadline;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, String> _answers = {};
  int _index = 0;

  Timer? _ticker;
  Timer? _saveDebounce;
  bool _dirty = false;
  bool _submitting = false;
  bool _submitted = false;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LiveArenaSocket.instance.join(widget.examId);
    _statusSub = LiveArenaSocket.instance.status.listen((s) {
      if (s['examId'] == widget.examId && s['status'] == 'CANCELLED') _onCancelled();
    });
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _saveDebounce?.cancel();
    _statusSub?.cancel();
    if (_dirty && !_submitted) _saveNow();
    LiveArenaSocket.instance.leave(widget.examId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_dirty) _saveNow();
    }
  }

  Future<void> _start({int retries = 0}) async {
    try {
      final res = await ApiService.startLiveExam(widget.examId);
      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        LiveArenaClock.sync(data['serverTime']);
        final attempt = Map<String, dynamic>.from(data['attempt']);
        final saved = (attempt['answers'] as List? ?? []);
        setState(() {
          _attemptId = attempt['_id'].toString();
          _attemptNumber = (attempt['attemptNumber'] as num).toInt();
          _isFirstAttempt = attempt['isFirstAttempt'] == true;
          _deadline = DateTime.parse(attempt['deadlineAt'].toString()).toLocal();
          _questions = (data['questions'] as List).map((q) => Map<String, dynamic>.from(q)).toList();
          for (final a in saved) {
            _answers[a['questionId'].toString()] = a['selectedKey'].toString();
          }
          _loading = false;
        });
        if (data['resumed'] == true && saved.isNotEmpty) {
          CustomToast.showInfo(context, 'Resumed — your saved answers are restored');
        }
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
        return;
      }

      // The local countdown can be a moment ahead of the server; wait for it.
      if (res.statusCode == 403 && data['code'] == 'NOT_STARTED' && retries < 5) {
        LiveArenaClock.sync(data['serverTime']);
        final startAt = DateTime.tryParse(data['startAt']?.toString() ?? '');
        final wait = startAt == null
            ? const Duration(seconds: 2)
            : startAt.toLocal().difference(LiveArenaClock.now()) + const Duration(milliseconds: 800);
        if (wait < const Duration(seconds: 15)) {
          await Future.delayed(wait.isNegative ? const Duration(seconds: 1) : wait);
          if (mounted) _start(retries: retries + 1);
          return;
        }
      }
      setState(() {
        _error = ApiService.getErrorMessage(res.body);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not start the exam. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  void _onTick() {
    if (!mounted || _deadline == null || _submitted) return;
    setState(() {});
    if (!LiveArenaClock.now().isBefore(_deadline!)) {
      _ticker?.cancel();
      _submit(auto: true);
    }
  }

  void _select(String questionId, String key) {
    setState(() => _answers[questionId] = key);
    _dirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1200), _saveNow);
  }

  Future<void> _saveNow() async {
    final id = _attemptId;
    if (id == null || _submitted) return;
    _dirty = false;
    try {
      final res = await ApiService.saveLiveExamAnswers(id, Map.of(_answers));
      if (res.statusCode != 200 && res.statusCode != 409) _dirty = true;
    } catch (_) {
      _dirty = true; // retried on the next change / pause / submit
    }
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _answers.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Submit exam?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. You cannot change answers after submitting.'
              : 'You cannot change answers after submitting.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok == true) _submit();
  }

  Future<void> _submit({bool auto = false}) async {
    final id = _attemptId;
    if (id == null || _submitting || _submitted) return;
    setState(() => _submitting = true);
    _saveDebounce?.cancel();
    if (auto && mounted) CustomToast.showInfo(context, "Time's up! Submitting your answers…");

    try {
      final res = await ApiService.submitLiveExam(id, Map.of(_answers));
      if (!mounted) return;
      if (res.statusCode == 200) {
        _submitted = true;
        _ticker?.cancel();
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveExamResultScreen(examId: widget.examId, initialResult: data),
          ),
        );
        return;
      }
      CustomToast.showError(context, ApiService.getErrorMessage(res.body));
    } catch (_) {
      if (mounted) {
        CustomToast.showError(
          context,
          'Could not reach the server. Your answers are saved — tap Submit again.',
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _onCancelled() {
    if (!mounted || _submitted) return;
    _ticker?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam cancelled'),
        content: const Text('This live exam was cancelled by your teacher.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave exam?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Your answers are saved and the timer keeps running. You can come back and resume until time is up.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true && mounted) {
      await _saveNow();
      if (mounted) Navigator.pop(context);
    }
  }

  String _remaining() {
    if (_deadline == null) return '--:--';
    var d = _deadline!.difference(LiveArenaClock.now());
    if (d.isNegative) d = Duration.zero;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  void _openPalette() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_answers.length} of ${_questions.length} answered',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_questions.length, (i) {
                final answered = _answers.containsKey(_questions[i]['_id'].toString());
                final current = i == _index;
                final primary = Theme.of(context).colorScheme.primary;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _index = i);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: answered ? primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: current ? Colors.orange : Colors.transparent, width: 2),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: answered ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: CustomLoader());
    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Live Exam'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'No questions found for this exam.', textAlign: TextAlign.center, style: GoogleFonts.poppins()),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final q = _questions[_index];
    final qid = q['_id'].toString();
    final options = (q['options'] as List? ?? []).map((o) => Map<String, dynamic>.from(o)).toList();
    final isLast = _index == _questions.length - 1;
    final lowTime = _deadline != null && _deadline!.difference(LiveArenaClock.now()).inSeconds <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: 'Question ${_index + 1}/${_questions.length}',
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
              onPressed: _openPalette,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.timer, color: lowTime ? Colors.orangeAccent : Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _remaining(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: lowTime ? Colors.orangeAccent : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isFirstAttempt)
                Container(
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Practice attempt #$_attemptNumber — not counted on the leaderboard',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(22),
                        constraints: const BoxConstraints(minHeight: 110),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((q['questionImage']?.toString() ?? '').isNotEmpty && q['questionImage'] != 'null')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    ApiService.getFileUrl(q['questionImage'].toString()),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white, size: 40),
                                  ),
                                ),
                              ),
                            Text(
                              q['questionText']?.toString() ?? '',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: options.map((o) {
                            final key = o['key'].toString();
                            final selected = _answers[qid] == key;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected ? theme.colorScheme.primary.withValues(alpha: 0.6) : Colors.grey[200]!,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: _submitting ? null : () => _select(qid, key),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: selected ? theme.colorScheme.primary : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          key,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: selected ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o['text']?.toString() ?? '',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            if ((o['image']?.toString() ?? '').isNotEmpty && o['image'] != 'null')
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Image.network(
                                                  ApiService.getFileUrl(o['image'].toString()),
                                                  height: 110,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _index > 0 ? () => setState(() => _index--) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : isLast
                              ? _confirmSubmit
                              : () => setState(() => _index++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? Colors.green.shade600 : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isLast ? 'Submit' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
