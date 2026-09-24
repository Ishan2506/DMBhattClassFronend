import 'dart:convert';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_arena_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/live_arena/live_exam_leaderboard_screen.dart';
import 'package:dm_bhatt_tutions/utils/live_arena_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Result of one Live Exam attempt. Rank and leaderboard score always come
/// from the student's FIRST attempt, as decided by the server.
class LiveExamResultScreen extends StatefulWidget {
  final String examId;
  final String? attemptId;
  final Map<String, dynamic>? initialResult;

  const LiveExamResultScreen({
    super.key,
    required this.examId,
    this.attemptId,
    this.initialResult,
  });

  @override
  State<LiveExamResultScreen> createState() => _LiveExamResultScreenState();
}

class _LiveExamResultScreenState extends State<LiveExamResultScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _data = widget.initialResult;
      LiveArenaClock.sync(_data!['serverTime']);
    } else {
      _load(widget.attemptId);
    }
  }

  Future<void> _load(String? attemptId) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getLiveExamResult(widget.examId, attemptId: attemptId);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        LiveArenaClock.sync(data['serverTime']);
        setState(() {
          _data = data;
          _error = null;
        });
      } else {
        setState(() => _error = ApiService.getErrorMessage(res.body));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your result.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Live Exam Result'),
      body: _loading
          ? const CustomLoader()
          : _data == null
              ? Center(child: Text(_error ?? 'No result found', style: GoogleFonts.poppins()))
              : RefreshIndicator(
                  onRefresh: () => _load(_data?['attempt']?['_id']?.toString()),
                  child: _body(_data!),
                ),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final colorScheme = Theme.of(context).colorScheme;
    final exam = Map<String, dynamic>.from(d['exam'] ?? {});
    final attempt = Map<String, dynamic>.from(d['attempt'] ?? {});
    final board = Map<String, dynamic>.from(d['leaderboard'] ?? {});
    final isFirst = attempt['isFirstAttempt'] == true;
    final autoSubmitted = attempt['status'] == 'AUTO_SUBMITTED';
    final passed = d['passed'];
    final review = d['review'] as List?;
    final attempts = (d['attempts'] as List? ?? []).map((a) => Map<String, dynamic>.from(a)).toList();
    final endAt = DateTime.tryParse(exam['endAt']?.toString() ?? '')?.toLocal();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Text(
                isFirst ? 'Exam Completed 🎉' : 'Practice Attempt Completed',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                exam['title']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text('Your Score', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              Text(
                '${formatMarks(attempt['obtainedMarks'] as num?)} / ${formatMarks(attempt['totalMarks'] as num?)}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
              ),
              if (autoSubmitted)
                Text('Auto-submitted when time ran out', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              if (passed is bool)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    passed ? 'PASSED' : 'NOT PASSED',
                    style: GoogleFonts.poppins(
                      color: passed ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _tile('Correct', '${attempt['correctCount'] ?? 0}', Colors.green.shade600),
            const SizedBox(width: 10),
            _tile('Wrong', '${attempt['wrongCount'] ?? 0}', Colors.red.shade500),
            const SizedBox(width: 10),
            _tile('Skipped', '${attempt['skippedCount'] ?? 0}', Colors.grey.shade600),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Rank', board['rank'] != null ? '#${board['rank']} of ${board['totalRanked']}' : '—'),
                _row('First Attempt', isFirst ? 'Yes' : 'No'),
                if (!isFirst) ...[
                  _row('Attempt', '${attempt['attemptNumber']}'),
                  _row(
                    'Leaderboard Score',
                    '${formatMarks(board['score'] as num?)} / ${formatMarks(board['totalMarks'] as num?)}',
                  ),
                ],
                _row('Time Taken', formatTimeTaken(attempt['timeTakenMs'] as num?)),
                const SizedBox(height: 6),
                Text(
                  isFirst
                      ? 'This attempt is your leaderboard score.'
                      : 'Only your first attempt counts on the leaderboard. This practice score does not change your rank.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveExamLeaderboardScreen(examId: widget.examId, title: exam['title']?.toString()),
              ),
            ),
            icon: const Icon(Icons.leaderboard_rounded),
            label: Text('View Leaderboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (attempts.length > 1) ...[
          const SizedBox(height: 20),
          Text('Your attempts', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ...attempts.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: a['isFirstAttempt'] == true ? colorScheme.primary : Colors.grey.shade300,
                  child: Text('${a['attemptNumber']}', style: TextStyle(color: a['isFirstAttempt'] == true ? Colors.white : Colors.black87)),
                ),
                title: Text(
                  '${formatMarks(a['obtainedMarks'] as num?)} / ${formatMarks(a['totalMarks'] as num?)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  a['isFirstAttempt'] == true ? 'First attempt · counts on leaderboard' : 'Practice',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: a['_id'].toString() == attempt['_id'].toString()
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: a['status'] == 'IN_PROGRESS' ? null : () => _load(a['_id'].toString()),
              )),
        ],
        const SizedBox(height: 20),
        if (review == null)
          Text(
            endAt != null
                ? 'Correct answers will be shown after the exam ends at ${formatLiveTime(endAt)}.'
                : 'Correct answers will be shown after the exam ends.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          )
        else ...[
          Text('Answer Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ...review.asMap().entries.map((e) => _reviewCard(e.key, Map<String, dynamic>.from(e.value))),
        ],
      ],
    );
  }

  Widget _tile(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            const Spacer(),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _reviewCard(int index, Map<String, dynamic> q) {
    final options = (q['options'] as List? ?? []).map((o) => Map<String, dynamic>.from(o)).toList();
    final selected = q['selectedKey']?.toString();
    final correct = q['correctAnswer']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ${q['questionText'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...options.map((o) {
              final key = o['key'].toString();
              final isCorrect = key == correct;
              final isPicked = key == selected;
              final color = isCorrect ? Colors.green.shade700 : (isPicked ? Colors.red.shade600 : Colors.grey.shade800);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : (isPicked ? Icons.cancel : Icons.radio_button_unchecked),
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$key. ${o['text'] ?? ''}', style: GoogleFonts.poppins(fontSize: 13, color: color)),
                    ),
                  ],
                ),
              );
            }),
            if (selected == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Not answered', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
              ),
          ],
        ),
      ),
    );
  }
}
